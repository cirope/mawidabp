module Reports::WeaknessesReport
  extend ActiveSupport::Concern

  included do
    before_action :set_weaknesses_for_report, only: [:weaknesses_report, :create_weaknesses_report]
  end

  def weaknesses_report
    @title = t '.title'
  end

  def create_weaknesses_report
    pdf_id = rand 1_000_000
    pdf    = init_pdf params[:report_title], params[:report_subtitle]

    @weaknesses.each do |weakness|
      add_to_weakness_report_pdf pdf, weakness
    end

    add_weaknesses_count_to_pdf pdf
    add_filter_options_to_pdf pdf

    full_path    = pdf.custom_save_as weaknesses_report_pdf_name, 'weaknesses_report', pdf_id
    @report_path = full_path.sub Rails.root.to_s, ''

    respond_to do |format|
      format.html { redirect_to @report_path }
      format.js { render 'shared/pdf_report' }
    end
  end

  private

    def set_weaknesses_for_report
      report_params = params[:weaknesses_report]

      if report_params.present?
        @weaknesses = filter_weaknesses_for_report report_params
      else
        @weaknesses = Weakness.none
      end
    end

    def scoped_weaknesses
      params[:execution].present? ?
        Weakness.list_without_final_review : Weakness.list_with_final_review
    end

    def filter_weaknesses_for_report report_params
      weaknesses = scoped_weaknesses.finals false

      %i(review project process_control control_objective tags).each do |param|
        if report_params[param].present?
          weaknesses = weaknesses.send "by_#{param}", report_params[param]
        end
      end

      if report_params[:user_id].present?
        weaknesses = weaknesses.by_user_id report_params[:user_id],
          include_finding_answers: report_params[:user_in_comments] == '1'
      end

      if report_params[:finding_status].present?
        weaknesses = weaknesses.where state: report_params[:finding_status]
      end

      if report_params[:finding_current_situation_verified].present?
        verified   = report_params[:finding_current_situation_verified] == 'yes'
        weaknesses = weaknesses.where current_situation_verified: verified
      end

      if report_params[:repeated].present?
        if report_params[:repeated] == 'true'
          weaknesses = weaknesses.where.not repeated_of: nil
        else
          weaknesses = weaknesses.where repeated_of: nil
        end
      end

      if report_params[:compliance].present?
        weaknesses = weaknesses.where compliance: report_params[:compliance]
      end

      if report_params[:finding_title].present?
        weaknesses = weaknesses.with_title report_params[:finding_title]
      end

      %i(risk priority).each do |param|
        if report_params[param].present?
          weaknesses = weaknesses.where param => report_params[param]
        end
      end

      if report_params[:issue_date].present?
        weaknesses = weaknesses.by_issue_date *parse_date_field(report_params, :issue_date)
      end

      %i(origination_date follow_up_date solution_date).each do |date_field|
        if report_params[date_field].present?
          operator, date, date_until = *parse_date_field(report_params, date_field)

          mask       = date_until ? '? AND ?' : '?'
          condition  = "#{Weakness.qcn date_field} #{operator} #{mask}"
          weaknesses = weaknesses.where condition, *[date, date_until].compact
        end
      end

      if params[:execution].blank?
        weaknesses.order [
          Arel.sql("#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'issue_date'} ASC"),
          review_code: :asc
        ]
      else
        weaknesses.order [
          Arel.sql("#{Review.quoted_table_name}.#{Review.qcn 'created_at'} ASC"),
          review_code: :asc
        ]
      end
    end

    def safe_date_operator operator
      %w(= < > <= >= between).include?(operator) ? operator : '='
    end

    def parse_date_field report_params, field_name
      operator     = safe_date_operator report_params["#{field_name}_operator"]
      date         = Timeliness.parse(report_params[field_name], :date).to_date
      date_until   = Timeliness.parse(report_params["#{field_name}_until"], :date)&.to_date
      date_until ||= date if operator == 'between'

      [operator.upcase, date, date_until]
    end

    def weaknesses_report_pdf_name
      params[:execution].present? ?
        t('execution_reports.weaknesses_report.pdf_name') :
        t('follow_up_audit.weaknesses_report.pdf_name')
    end

    def add_weaknesses_count_to_pdf pdf
      pdf.text I18n.t(
        'follow_up_audit.weaknesses_report.weaknesses_count',
        count: @weaknesses.count
      )

      pdf.move_down PDF_FONT_SIZE
    end

    def add_to_weakness_report_pdf pdf, weakness
      issue_date = weakness.issue_date ?
        l(weakness.issue_date, format: :long) :
        t('finding.without_conclusion_final_review')
      subtitle = [
        weakness.review_code,
        weakness.review.identification
      ].join(' - ')

      pdf.add_subtitle subtitle

      pdf.move_down (PDF_FONT_SIZE * 1.25).round

      pdf.add_description_item(Review.model_name.human, "#{weakness.review.long_identification} (#{issue_date})", 0, false)
      pdf.add_description_item(Weakness.human_attribute_name(:review_code), weakness.review_code, 0, false)
      pdf.add_description_item(Weakness.human_attribute_name(:title), weakness.title, 0, false)

      pdf.add_description_item(ProcessControl.model_name.human, weakness.control_objective_item.process_control.name, 0, false)
      pdf.add_description_item(Weakness.human_attribute_name(:control_objective_item_id), weakness.control_objective_item.to_s, 0, false)
      pdf.add_description_item(Weakness.human_attribute_name(:description), weakness.description, 0, false)
      pdf.add_description_item(Weakness.human_attribute_name(:state), weakness.state_text, 0, false)

      pdf.add_description_item(Weakness.human_attribute_name(:risk), weakness.risk_text, 0, false)
      pdf.add_description_item(Weakness.human_attribute_name(:priority), weakness.priority_text, 0, false) unless HIDE_WEAKNESS_PRIORITY
      pdf.add_description_item(Weakness.human_attribute_name(:effect), weakness.effect, 0, false) unless HIDE_WEAKNESS_EFFECT
      pdf.add_description_item(Weakness.human_attribute_name(:audit_recommendations), weakness.audit_recommendations, 0, false)

      pdf.add_description_item(Weakness.human_attribute_name(:answer), weakness.answer, 0, false)

      if SHOW_FINDING_CURRENT_SITUATION
        current_situation_verified = I18n.t "label.#{weakness.current_situation_verified ? 'yes' : 'no'}"

        pdf.add_description_item(Weakness.human_attribute_name(:current_situation), weakness.current_situation, 0, false)
        pdf.add_description_item(Weakness.human_attribute_name(:current_situation_verified), current_situation_verified, 0, false)
      end

      if weakness.follow_up_date
        pdf.add_description_item(Weakness.human_attribute_name(:follow_up_date), l(weakness.follow_up_date, format: :long), 0, false)
      end

      if weakness.solution_date
        pdf.add_description_item(Weakness.human_attribute_name(:solution_date), l(weakness.solution_date, format: :long), 0, false)
      end

      pdf.add_description_item(Weakness.human_attribute_name(:audit_comments), weakness.audit_comments, 0, false)

      if weakness.origination_date
        pdf.add_description_item(Weakness.human_attribute_name(:origination_date), l(weakness.origination_date, format: :long), 0, false)
      end

      audited = weakness.users.reload.select(&:can_act_as_audited?)

      pdf.add_title t('finding.responsibles', count: audited.size), PDF_FONT_SIZE, :left
      pdf.add_list audited.map(&:full_name), PDF_FONT_SIZE * 2

      if weakness.finding_answers.present?
        column_names = [['answer', 50], ['user_id', 30], ['created_at', 20]]
        column_headers, column_widths, column_data = [], [], []

        column_names.each do |col_name, col_size|
          column_headers << FindingAnswer.human_attribute_name(col_name)
          column_widths << pdf.percent_width(col_size)
        end

        weakness.finding_answers.reload.each do |finding_answer|
          column_data << [
            finding_answer.answer,
            finding_answer.user.try(:full_name),
            l(finding_answer.created_at, format: :validation)
          ]
        end

        pdf.move_down PDF_FONT_SIZE

        pdf.add_title t('finding.follow_up_report.follow_up_comments'), (PDF_FONT_SIZE * 1.25).round

        pdf.move_down PDF_FONT_SIZE

        if column_data.present?
          pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
            table_options = pdf.default_table_options(column_widths)

            pdf.table(column_data.insert(0, column_headers), table_options) do
              row(0).style(
                background_color: 'cccccc',
                padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
              )
            end
          end
        end
      end

      pdf.start_new_page
    end

    def add_filter_options_to_pdf pdf
      value_filter_names = %i(
        risk
        priority
        finding_status
        repeated
        compliance
        finding_current_situation_verified
        user_in_comments
      )
      filters            = []
      labels             = {
        review:                             Review.model_name.human,
        project:                            PlanItem.human_attribute_name('project'),
        process_control:                    ProcessControl.model_name.human,
        control_objective:                  ControlObjective.model_name.human,
        tags:                               Tag.model_name.human,
        user:                               User.model_name.human,
        user_in_comments:                   t('shared.filters.user.user_in_comments'),
        finding_status:                     Weakness.human_attribute_name('state'),
        finding_title:                      Weakness.human_attribute_name('title'),
        risk:                               Weakness.human_attribute_name('risk'),
        priority:                           Weakness.human_attribute_name('priority'),
        finding_current_situation_verified: Weakness.human_attribute_name('current_situation_verified'),
        repeated:                           t('findings.state.repeated'),
        compliance:                         Weakness.human_attribute_name('compliance'),
        issue_date:                         ConclusionFinalReview.human_attribute_name('issue_date'),
        origination_date:                   Weakness.human_attribute_name('origination_date'),
        follow_up_date:                     Weakness.human_attribute_name('follow_up_date'),
        solution_date:                      Weakness.human_attribute_name('solution_date')
      }
      report_params = params[:weaknesses_report].permit *labels.keys

      labels.each do |filter_name, filter_label|
        if report_params[filter_name].present?
          operator = report_params["#{filter_name}_operator"] || '='
          value = if value_filter_names.include?(filter_name)
                    value_to_label(filter_name)
                  else
                    report_params[filter_name]
                  end

          filters << "<b>#{filter_label}</b> #{operator} #{value}"
        end
      end

      add_pdf_filters pdf, 'follow_up', filters if filters.present?
    end

    def value_to_label param_name
      value = params[:weaknesses_report][param_name].to_i

      case param_name
      when :risk
        risk = Weakness.risks.detect { |r| r.last == value }

        risk ? t("risk_types.#{risk.first}") : ''
      when :priority
        priority = Weakness.priorities.detect { |p| p.last == value }

        priority ? t("priority_types.#{priority.first}") : ''
      when :finding_status
        t "findings.state.#{Finding::STATUS.invert[value]}"
      when :user_in_comments
        value == 1 ? t('label.yes') : t('label.no')
      when :finding_current_situation_verified
        t "label.#{params[:weaknesses_report][param_name]}"
      when :repeated
        value = params[:weaknesses_report][param_name] == 'true'

        value ? t('label.yes') : t('label.no')
      when :compliance
        value = params[:weaknesses_report][param_name] == 'yes'

        value ? t('label.yes') : t('label.no')
      end
    end
end
