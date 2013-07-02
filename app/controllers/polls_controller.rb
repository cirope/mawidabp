class PollsController < ApplicationController
  before_filter :load_privileges, :auth, :except => [:edit, :update, :show]
  before_filter :check_privileges, :except => [:edit, :update, :show]

  layout 'application'
  require 'csv'

  # GET /polls
  # GET /polls.json
  def index
    @current_module = "administration_questionnaires_polls"
    @title = t 'poll.index_title'
    if params[:id]
      @polls = Poll.by_questionnaire(params[:id]).paginate(
        :page => params[:page], :per_page => APP_LINES_PER_PAGE)
    else
      default_conditions = {
        :organization_id => @auth_organization.id
      }

      build_search_conditions Poll, default_conditions

      unless @columns.first == 'answered' && @columns.size == 1
        @polls = Poll.includes(
          :questionnaire,
          :user
        ).where(@conditions).order(
          "#{Poll.table_name}.created_at DESC"
        ).paginate(
          :page => params[:page], :per_page => APP_LINES_PER_PAGE
        )
      else
        # Solo busca por columna contestada
        if params[:search][:query].downcase == 'si'
          default_conditions[:answered] = true
        elsif params[:search][:query].downcase == 'no'
          default_conditions[:answered] = false
        end

        @polls = Poll.includes(
          :questionnaire,
          :user
        ).where(default_conditions).order(
          "#{Poll.table_name}.created_at DESC"
        ).paginate(
          :page => params[:page], :per_page => APP_LINES_PER_PAGE
        )
      end
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @polls }
    end
  end

  # GET /polls/1
  # GET /polls/1.json
  def show
    @title = t 'poll.show_title'
    @poll = Poll.find params[:id]

    if params[:layout]
      @layout = params[:layout]
    else
      @layout = 'application'
    end

    respond_to do |format|
      if @poll.present?
        format.html { render :layout => @layout } # show.html.erb
        format.json { render :json => @poll }
      else
        format.html { redirect_to polls_url, :alert => (t 'poll.not_found') }
      end
    end
  end

  # GET /polls/new
  # GET /polls/new.json
  def new
    @title = t 'poll.new_title'
    @poll = Poll.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @poll }
    end
  end

  # GET /polls/1/edit
  def edit
    @title = t 'poll.edit_title'
    @poll = Poll.find(params[:id])

    if @poll.nil? || params[:token] != @poll.access_token
      redirect_to login_users_url, :alert => (t 'poll.not_found')
    elsif @poll.answered?
      redirect_to poll_path(@poll, :layout => 'application_clean'), :alert => (t 'poll.access_denied')
    end
  end

  # POST /polls
  # POST /polls.json
  def create
    @title = t 'poll.new_title'
    @poll = Poll.new(params[:poll])
    @poll.organization = @auth_organization
    polls = Poll.between_dates(Date.today.at_beginning_of_day, Date.today.end_of_day).where(
              :questionnaire_id => @poll.questionnaire.id,
              :user_id => @poll.user.id
            )

    respond_to do |format|
      if !polls.empty?
        format.html { redirect_to new_poll_path, :alert => (t 'poll.already_exists') }
      elsif @poll.save
        format.html { redirect_to @poll, :notice => (t 'poll.correctly_created') }
        format.json { render :json => @poll, :status => :created, :location => @poll }
      else
        format.html { render :action => 'new' }
        format.json { render :json => @poll.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /polls/1
  # PUT /polls/1.json
  def update
    @title = t 'poll.edit_title'
    @poll = Poll.find(params[:id])

    respond_to do |format|
      if @poll.nil?
        format.html { redirect_to login_users_url, :alert => (t 'poll.not_found') }
      elsif @poll.update_attributes(params[:poll])
        if @auth_user
          format.html { redirect_to login_users_url, :notice => (t 'poll.correctly_updated') }
        else
          format.html { redirect_to poll_url(@poll, :layout => 'application_clean'), :notice => (t 'poll.correctly_updated') }
        end
        format.json { head :ok }
      else
        format.html { render :action => 'edit' }
        format.json { render :json => @poll.errors, :status => :unprocessable_entity }
      end
    end
  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'poll.stale_object_error'
    redirect_to :action => :edit
  end

  # DELETE /polls/1
  # DELETE /polls/1.json
  def destroy
    @poll = Poll.find(params[:id])
    @poll.destroy

    respond_to do |format|
      format.html { redirect_to polls_url }
      format.json { head :ok }
    end
  end

   # * GET /polls/auto_complete_for_user
  def auto_complete_for_user
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = [
      "#{Organization.table_name}.id = :organization_id",
      "#{User.table_name}.hidden = false"
    ]
    conditions << "#{User.table_name}.id <> :self_id" if params[:user_id]
    parameters = {
      :organization_id => @auth_organization.id,
      :self_id => params[:user_id]
    }
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{User.table_name}.name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.last_name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.function) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.user) LIKE :user_data_#{i}"
      ].join(' OR ')

      parameters[:"user_data_#{i}"] = "%#{Unicode::downcase(t)}%"
    end

    @users = User.includes(:organizations).where(
      conditions.map {|c| "(#{c})"}.join(' AND '), parameters
    ).order(
      ["#{User.table_name}.last_name ASC", "#{User.table_name}.name ASC"]
    ).limit(10)

    respond_to do |format|
      format.json { render :json => @users }
    end
  end

  def reports
    @title = t 'poll.reports_title'
  end

  def summary_by_questionnaire
    @title = t 'poll.reports_title'
    @from_date, @to_date = *make_date_range(params[:summary_by_questionnaire])
    @questionnaires = Questionnaire.list.map { |q| [q.name, q.id.to_s] }
    @questionnaire = Questionnaire.find(params[:summary_by_questionnaire][:questionnaire]) if params[:summary_by_questionnaire]

    if @questionnaire
      @polls = Poll.between_dates(@from_date.at_beginning_of_day, @to_date.end_of_day
                 ).by_questionnaire(@questionnaire)
      @rates, @answered, @unanswered = @questionnaire.answer_rates @polls
      count = 0
      total = 0
      @polls.each do |poll|
        if poll.answered?
          poll.answers.each do |answer|
            if answer.answer_option.present?
              count += Question::ANSWER_OPTION_VALUES[answer.answer_option.option.to_sym]
              total += 1
            end
          end
        end
      end
      total == 0 ? @calification = 0 : @calification = (count / total).round
    end
  end

  def create_summary_by_questionnaire
    self.summary_by_questionnaire

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE * 2

    pdf.add_description_item(
      t('activerecord.attributes.poll.send_date'),
        t('conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    pdf.move_down PDF_FONT_SIZE

    if @polls.present?
      pdf.add_description_item(
        Questionnaire.model_name.human,
        @questionnaire.name)

      pdf.move_down PDF_FONT_SIZE * 2

      column_data, column_headers, column_widths = [], [], []

      @columns = [
        [Question.model_name.human, 40]
      ]
      Question::ANSWER_OPTIONS.each do |option|
        @columns << [t("activerecord.attributes.answer_option.options.#{option}"), 12]
      end

      @columns.each do |col_title, col_width|
        column_headers << "<b>#{col_title}</b>"
        column_widths << pdf.percent_width(col_width)
      end

      @rates.each do |question, answers|
        new_row = []
        new_row << question

        Question::ANSWER_OPTIONS.each_with_index do |option, i|
          new_row << "#{answers[i]} %"
        end

        column_data << new_row
      end

      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(column_widths)

        pdf.table(column_data.insert(0, column_headers), table_options) do
          row(0).style(
            :background_color => 'cccccc',
            :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end

      pdf.move_down PDF_FONT_SIZE

      pdf.text "#{t('poll.total_answered')}: #{@answered}"
      pdf.text "#{t('poll.total_unanswered')}: #{@unanswered}"
      pdf.move_down PDF_FONT_SIZE
      pdf.text "#{t('poll.score')}: #{@calification}%"
    else
      pdf.text t('poll.without_data')
    end

    pdf.custom_save_as(t('poll.summary_pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'summary_by_questionnaire', 0)

    redirect_to Prawn::Document.relative_path(t('poll.summary_pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'summary_by_questionnaire', 0)

  end

  def summary_by_answers
    parameters = params[:summary_by_answers]
    @title = t 'poll.reports_title'
    @answered = nil
    @from_date, @to_date = *make_date_range(parameters)
    @questionnaires = Questionnaire.list.map { |q| [q.name, q.id.to_s] }

    if parameters
      @questionnaire = Questionnaire.find(parameters[:questionnaire])
      @answered = parameters[:answered] == 'true' if parameters[:answered].present?
    end

    if @questionnaire
      @polls = @answered.nil? ?
        Poll.between_dates(@from_date.at_beginning_of_day, @to_date.end_of_day
          ).by_questionnaire(@questionnaire) :
        Poll.between_dates(@from_date.at_beginning_of_day, @to_date.end_of_day
          ).by_questionnaire(@questionnaire).answered(@answered)
      @rates, @answered, @unanswered = @questionnaire.answer_rates @polls
      count = 0
      total = 0
      @polls.each do |poll|
        if poll.answered?
          poll.answers.each do |answer|
            if answer.answer_option.present?
              count += Question::ANSWER_OPTION_VALUES[answer.answer_option.option.to_sym]
              total += 1
            end
          end
        end
      end
      total == 0 ? @calification = 0 : @calification = (count / total).round
    end
  end

  def create_summary_by_answers
    self.summary_by_answers

    pdf = Prawn::Document.create_generic_pdf :portrait

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE * 2

    pdf.add_description_item(
      t('activerecord.attributes.poll.send_date'),
        t('conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    pdf.move_down PDF_FONT_SIZE

    if @polls.present?
      pdf.add_description_item(
        Questionnaire.model_name.human,
        @questionnaire.name)

      pdf.move_down PDF_FONT_SIZE * 2

      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        @polls.each do |poll|
          if poll.user.present?
            pdf.text "#{Poll.human_attribute_name :user_id}: #{poll.user.informal_name}", :style => :bold
          elsif poll.customer_email.present?
            pdf.text "#{Poll.human_attribute_name :customer_email}: #{poll.customer_email}", :style => :bold
          end

          pdf.text "#{Poll.human_attribute_name :answered}: #{poll.answered ? t('label.yes') : t('label.no')}"

          pdf.text "#{Poll.human_attribute_name(:send_date)}: #{l poll.created_at.to_date, :format => :long}"

          if poll.answered?
            pdf.text "#{Poll.human_attribute_name(:answer_date)}: #{l poll.updated_at.to_date, :format => :long}"
          end

          pdf.text "#{Questionnaire.human_attribute_name :questions}:"

          poll.answers.each do |answer|
            ans = ''
            if poll.answered?
              if answer.question.answer_multi_choice?
                ans = "#{t("activerecord.attributes.answer_option.options.#{answer.answer_option.option}")}"
              elsif answer.question.answer_written?
                ans = answer.answer
              end
            end

            pdf.text "#{answer.question.question} #{ans}"

            if answer.comments.present?
              pdf.text "#{Answer.human_attribute_name :comments}: #{answer.comments}"
            end
          end

          if poll.comments.present?
            pdf.text "#{Poll.human_attribute_name :comments}: #{poll.comments}"
          end

          pdf.move_down PDF_FONT_SIZE
        end
      end

      pdf.move_down PDF_FONT_SIZE

      pdf.text "#{t('poll.total_answered')}: #{@answered}"
      pdf.text "#{t('poll.total_unanswered')}: #{@unanswered}"
      pdf.move_down PDF_FONT_SIZE
      pdf.text "#{t('poll.score')}: #{@calification}%"
    else
      pdf.text t('poll.without_data')
    end

    pdf.custom_save_as(t('poll.summary_pdf_name',
      :from_date => @from_date.to_formatted_s(:db),
      :to_date => @to_date.to_formatted_s(:db)), 'summary_by_answers', 0)
    redirect_to Prawn::Document.relative_path(t('poll.summary_pdf_name',
      :from_date => @from_date.to_formatted_s(:db),
      :to_date => @to_date.to_formatted_s(:db)), 'summary_by_answers', 0)

  end

  def summary_by_business_unit
    @title = t 'poll.reports_title'
    @from_date, @to_date = *make_date_range(params[:summary_by_business_unit])
    @questionnaires = Questionnaire.list.pollable.map { |q| [q.name, q.id.to_s] }
    conclusion_reviews = ConclusionFinalReview.list_all_by_date(@from_date.months_ago(3),
      @to_date)
    @business_unit_polls = {}

    if params[:summary_by_business_unit]
      questionnaire_id = params[:summary_by_business_unit][:questionnaire]
      @questionnaire = Questionnaire.find(questionnaire_id) if questionnaire_id
      polls = Poll.between_dates(@from_date.at_beginning_of_day, @to_date.end_of_day
                 ).by_questionnaire(@questionnaire).pollables

      unless params[:summary_by_business_unit][:business_unit_type].blank?
         @selected_business_unit = BusinessUnitType.find(
          params[:summary_by_business_unit][:business_unit_type])
        conclusion_reviews = conclusion_reviews.by_business_unit_type(@selected_business_unit.id)
      end

      unless params[:summary_by_business_unit][:business_unit].blank?
        business_units = params[:summary_by_business_unit][:business_unit].split(
          SPLIT_AND_TERMS_REGEXP
        ).uniq.map(&:strip)

        unless business_units.empty?
          conclusion_reviews = conclusion_reviews.by_business_unit_names(*business_units)
        end
      end

      if conclusion_reviews.present?
        filtered_polls = polls.select { |poll| conclusion_reviews.include? poll.pollable }

        if @selected_business_unit
          but_polls =  filtered_polls.select { |poll|
            poll.pollable.review.plan_item.business_unit.business_unit_type == @selected_business_unit
          }

          if but_polls.present?
            @business_unit_polls[@selected_business_unit.name] = {}
            rates, answered, unanswered = @questionnaire.answer_rates(but_polls)
            @business_unit_polls[@selected_business_unit.name][:rates] = rates
            @business_unit_polls[@selected_business_unit.name][:answered] = answered
            @business_unit_polls[@selected_business_unit.name][:unanswered] = unanswered
            count = 0
            total = 0
            but_polls.each do |poll|
              if poll.answered?
                poll.answers.each do |answer|
                  if answer.answer_option.present?
                    count += Question::ANSWER_OPTION_VALUES[answer.answer_option.option.to_sym]
                    total += 1
                  end
                end
              end
            end
            total == 0 ? calification = 0 : calification = (count / total).round
            @business_unit_polls[@selected_business_unit.name][:calification] = calification
          end
        else
          BusinessUnitType.list.each do |but|
            but_polls =  polls.select { |poll|
              poll.pollable.review.plan_item.business_unit.business_unit_type == but
            }
            if but_polls.present?
              @business_unit_polls[but.name] = {}
              rates, answered, unanswered = @questionnaire.answer_rates(but_polls)
              @business_unit_polls[but.name][:rates] = rates
              @business_unit_polls[but.name][:answered] = answered
              @business_unit_polls[but.name][:unanswered] = unanswered
              count = 0
              total = 0
              but_polls.each do |poll|
                if poll.answered?
                  poll.answers.each do |answer|
                    if answer.answer_option.present?
                      count += Question::ANSWER_OPTION_VALUES[answer.answer_option.option.to_sym]
                      total += 1
                    end
                  end
                end
              end
              total == 0 ? calification = 0 : calification = (count / total).round
              @business_unit_polls[but.name][:calification] = calification
            end
          end
        end
      end
    end
  end

  def create_summary_by_business_unit
    self.summary_by_business_unit

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE * 2

    pdf.add_description_item(
      t('activerecord.attributes.poll.send_date'),
      t('conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    pdf.move_down PDF_FONT_SIZE

    if @business_unit_polls.present?
      pdf.add_description_item(Questionnaire.model_name.human, @questionnaire.name)

      pdf.move_down PDF_FONT_SIZE * 2

      @columns = [
        [Question.model_name.human, 40]
      ]
      Question::ANSWER_OPTIONS.each do |option|
        @columns << [t("activerecord.attributes.answer_option.options.#{option}"), 12]
      end

      column_headers, column_widths = [], []

      @columns.each do |col_title, col_width|
        column_headers << "<b>#{col_title}</b>"
        column_widths << pdf.percent_width(col_width)
      end

      @business_unit_polls.each_key do |but|
        pdf.text "<b>#{but}</b>", :font_size => PDF_FONT_SIZE * 1.3, :inline_format => true
        pdf.move_down PDF_FONT_SIZE * 2
        column_data = []

        @business_unit_polls[but][:rates].each do |question, answers|
          new_row = []
          new_row << question

          Question::ANSWER_OPTIONS.each_with_index do |option, i|
            new_row << "#{answers[i]} %"
          end

          column_data << new_row
        end

        pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
          table_options = pdf.default_table_options(column_widths)

          pdf.table(column_data.insert(0, column_headers), table_options) do
            row(0).style(
              :background_color => 'cccccc',
              :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
            )
          end
        end

        pdf.move_down PDF_FONT_SIZE

        pdf.text "#{t('poll.total_answered')}: #{@business_unit_polls[but][:answered]}"
        pdf.text "#{t('poll.total_unanswered')}: #{@business_unit_polls[but][:unanswered]}"
        pdf.move_down PDF_FONT_SIZE
        pdf.text "#{t('poll.score')}: #{@business_unit_polls[but][:calification]}%"
        pdf.move_down PDF_FONT_SIZE * 2
      end
    else
      pdf.text t('poll.without_data')
    end

    pdf.custom_save_as(t('poll.summary_pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'summary_by_business_unit', 0)

    redirect_to Prawn::Document.relative_path(t('poll.summary_pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'summary_by_business_unit', 0)

  end

  def import_csv_customers
    @title = t('poll.import_csv_customers_title')
  end

  def send_csv_polls
    if params[:dump_emails] && File.extname(params[:dump_emails][:file].original_filename).downcase == '.csv'

      uploaded_file = params[:dump_emails][:file]
      file_name = uploaded_file.path
      questionnaire_id = params[:dump_emails][:questionnaire_id].to_i

      text = File.read(
        file_name,
        { :encoding => 'UTF-8',
          :delimiter => ';'
        }
      )

      @parsed_file = CSV.parse(text)
      n = 0

      @parsed_file.each  do |row|
        poll = Poll.new(
          :questionnaire_id => questionnaire_id,
          :organization_id => @auth_organization.id
        )
        poll.customer_email = row[0]

        if poll.save
          n+=1
        end
      end

      flash[:notice] = t('poll.customer_polls_sended', :count => n)
    else

      flash[:alert] = t('poll.error_csv_file_extension')
    end

    respond_to do |format|
      format.html { redirect_to polls_path }
    end
  end

  def load_privileges #:nodoc:
    if @action_privileges
      @action_privileges.update(
        :auto_complete_for_user => :read,
        :reports => :read,
        :summary_by_answers => :read,
        :create_summary_by_answers => :read,
        :summary_by_business_unit => :read,
        :create_summary_by_business_unit => :read,
        :summary_by_questionnaire => :read,
        :create_summary_by_questionnaire => :read,
        :auto_complete_for_user => :read,
        :import_csv_customers => :read
      )
    end
  end
end


