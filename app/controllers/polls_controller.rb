class PollsController < ApplicationController
  before_filter :load_privileges, :auth, :except => [:edit, :update, :show]
  before_filter :check_privileges, :except => [:edit, :update, :show]

  layout 'application'

  # GET /polls
  # GET /polls.json
  def index
    @title = t 'poll.index_title'
    if params[:id]
      @polls = Poll.by_questionnaire(params[:id]).paginate(
        :page => params[:page], :per_page => APP_LINES_PER_PAGE)
    else
      default_conditions = {
        Poll.table_name => {:organization_id => @auth_organization.id}
      }

      build_search_conditions Poll, default_conditions

      @polls = Poll.includes(
        :questionnaire,
        :user
      ).where(@conditions).order(
        "#{Poll.table_name}.created_at"
      ).paginate(
        :page => params[:page], :per_page => APP_LINES_PER_PAGE
      )
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

    respond_to do |format|
      if @poll.save
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
    end
  end

  def create_summary_by_questionnaire
    self.summary_by_questionnaire

    pdf = PDF::Writer.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE * 2

    pdf.add_description_item(
      t('activerecord.attributes.poll.send_date'),
        t('conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    pdf.move_pointer PDF_FONT_SIZE

    if @polls.present?
      pdf.add_description_item(
        Questionnaire.model_name.human,
        @questionnaire.name)

      pdf.move_pointer PDF_FONT_SIZE * 2

      column_data = []
      columns = {}
      @columns = [
        ['question', Question.model_name.human, 40]
      ]
      Question::ANSWER_OPTIONS.each do |option|
        @columns << [option, t("activerecord.attributes.answer_option.options.#{option}"), 12]
      end

      @columns.each do |col_name, col_title, col_width|
        columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |column|
          column.heading = col_title
          column.width = pdf.percent_width col_width
        end
      end

      @rates.each do |question, answers|
        new_row = {}
        new_row['question'] = question.to_iso

        Question::ANSWER_OPTIONS.each_with_index do |option, i|
          new_row[option] = "#{answers[i]} %"
        end

        column_data << new_row
      end

      PDF::SimpleTable.new do |table|
        table.width = pdf.page_usable_width
        table.columns = columns
        table.data = column_data
        table.column_order = @columns.map(&:first)
        table.split_rows = true
        table.row_gap = PDF_FONT_SIZE
        table.font_size = (PDF_FONT_SIZE * 0.75).round
        table.shade_color = Color::RGB.from_percentage(95, 95, 95)
        table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
        table.heading_font_size = PDF_FONT_SIZE
        table.shade_headings = true
        table.position = :left
        table.orientation = :right
        table.render_on pdf
      end
      pdf.move_pointer PDF_FONT_SIZE

      pdf.text "#{t('poll.total_answered')}: #{@answered}"
      pdf.text "#{t('poll.total_unanswered')}: #{@unanswered}"
    else
      pdf.text t('poll.without_data')
    end

    pdf.custom_save_as(t('poll.summary_pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'summary_by_questionnaire', 0)

    redirect_to PDF::Writer.relative_path(t('poll.summary_pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'summary_by_questionnaire', 0)

  end

  def summary_by_business_unit
    @title = t 'poll.reports_title'
    @from_date, @to_date = *make_date_range(params[:summary_by_business_unit])
    @questionnaires = Questionnaire.pollable.map { |q| [q.name, q.id.to_s] }
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
            end
          end
        end
      end
    end
  end

  def create_summary_by_business_unit
    self.summary_by_business_unit

    pdf = PDF::Writer.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE * 2

    pdf.add_description_item(
      t('activerecord.attributes.poll.send_date'),
      t('conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    pdf.move_pointer PDF_FONT_SIZE

    if @business_unit_polls.present?
      pdf.add_description_item(Questionnaire.model_name.human, @questionnaire.name)

      pdf.move_pointer PDF_FONT_SIZE * 2

      columns = {}
      @columns = [
        ['question', Question.model_name.human, 40]
      ]
      Question::ANSWER_OPTIONS.each do |option|
        @columns << [option, t("activerecord.attributes.answer_option.options.#{option}"), 12]
      end

      @columns.each do |col_name, col_title, col_width|
        columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |column|
          column.heading = col_title
          column.width = pdf.percent_width col_width
        end
      end

      @business_unit_polls.each_key do |but|
        pdf.text but, :font_size => PDF_FONT_SIZE * 1.3
        pdf.move_pointer PDF_FONT_SIZE * 2
        column_data = []

        @business_unit_polls[but][:rates].each do |question, answers|
          new_row = {}
          new_row['question'] = question.to_iso

          Question::ANSWER_OPTIONS.each_with_index do |option, i|
            new_row[option] = "#{answers[i]} %"
          end

          column_data << new_row
        end

        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = column_data
          table.column_order = @columns.map(&:first)
          table.split_rows = true
          table.row_gap = PDF_FONT_SIZE
          table.font_size = (PDF_FONT_SIZE * 0.75).round
          table.shade_color = Color::RGB.from_percentage(95, 95, 95)
          table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
          table.heading_font_size = PDF_FONT_SIZE
          table.shade_headings = true
          table.position = :left
          table.orientation = :right
          table.render_on pdf
        end
        pdf.move_pointer PDF_FONT_SIZE

        pdf.text "#{t('poll.total_answered')}: #{@business_unit_polls[but][:answered]}"
        pdf.text "#{t('poll.total_unanswered')}: #{@business_unit_polls[but][:unanswered]}"
        pdf.move_pointer PDF_FONT_SIZE * 2
      end
    else
      pdf.text t('poll.without_data')
    end

    pdf.custom_save_as(t('poll.summary_pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'summary_by_business_unit', 0)

    redirect_to PDF::Writer.relative_path(t('poll.summary_pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'summary_by_business_unit', 0)

  end

  def load_privileges #:nodoc:
    if @action_privileges
      @action_privileges.update(
        :auto_complete_for_user => :read,
        :reports => :read,
        :summary_by_business_unit => :read,
        :create_summary_by_business_unit => :read,
        :summary_by_questionnaire => :read,
        :create_summary_by_questionnaire => :read
      )
    end
  end
end
