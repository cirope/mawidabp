module Findings::WeaknessReportPdf
  extend ActiveSupport::Concern

  module ClassMethods
    include Reports::BasePdf

    def to_weakness_report_pdf opts
      pdf   = init_pdf opts[:title], opts[:subtitle]
      count = 0

      SmartIterator.iterate all do |cursor|
        cursor.each do |weakness|
          add_to_weakness_report_pdf pdf, weakness

          count += 1
        end
      end

      add_weaknesses_count_to_pdf pdf, count
      add_filter_options_to_pdf pdf, opts[:report_params].with_indifferent_access

      if opts[:filename_only]
        pdf_id    = rand 1_000_000
        full_path = pdf.custom_save_as opts[:filename], 'weaknesses_report', pdf_id

        full_path.sub Rails.root.to_s, ''
      else
        pdf.render
      end
    end

    def add_weaknesses_count_to_pdf pdf, count
      pdf.text I18n.t(
        'follow_up_audit.weaknesses_report.weaknesses_count',
        count: count
      )

      pdf.move_down PDF_FONT_SIZE
    end

    def add_to_weakness_report_pdf pdf, weakness
      issue_date = weakness.issue_date ?
        I18n.l(weakness.issue_date, format: :long) :
        I18n.t('finding.without_conclusion_final_review')
      subtitle = [
        weakness.review_code,
        weakness.review.identification
      ].join(' - ')

      pdf.add_subtitle subtitle

      pdf.move_down (PDF_FONT_SIZE * 1.25).round

      pdf.add_description_item Review.model_name.human, "#{weakness.review.long_identification} (#{issue_date})", 0, false
      pdf.add_description_item Weakness.human_attribute_name(:review_code), weakness.review_code, 0, false
      pdf.add_description_item Weakness.human_attribute_name(:title), weakness.title, 0, false

      pdf.add_description_item ProcessControl.model_name.human, weakness.control_objective_item.process_control.name, 0, false
      pdf.add_description_item Weakness.human_attribute_name(:control_objective_item_id), weakness.control_objective_item.to_s, 0, false
      pdf.add_description_item Weakness.human_attribute_name(:description), weakness.description, 0, false
      pdf.add_description_item Weakness.human_attribute_name(:state), weakness.full_state_text, 0, false

      pdf.add_description_item Weakness.human_attribute_name(:risk), weakness.risk_text, 0, false
      pdf.add_description_item Weakness.human_attribute_name(:priority), weakness.priority_text, 0, false
      pdf.add_description_item Weakness.human_attribute_name(:effect), weakness.effect, 0, false unless HIDE_WEAKNESS_EFFECT
      pdf.add_description_item Weakness.human_attribute_name(:audit_recommendations), weakness.audit_recommendations, 0, false

      pdf.add_description_item Weakness.human_attribute_name(:answer), weakness.answer, 0, false

      if SHOW_FINDING_CURRENT_SITUATION
        current_situation_verified = I18n.t "label.#{weakness.current_situation_verified ? 'yes' : 'no'}"

        pdf.add_description_item Weakness.human_attribute_name(:current_situation), weakness.current_situation, 0, false
        pdf.add_description_item Weakness.human_attribute_name(:current_situation_verified), current_situation_verified, 0, false
      end

      if weakness.follow_up_date
        pdf.add_description_item Weakness.human_attribute_name(:follow_up_date), I18n.l(weakness.follow_up_date, format: :long), 0, false
      end

      if weakness.solution_date
        pdf.add_description_item Weakness.human_attribute_name(:solution_date), I18n.l(weakness.solution_date, format: :long), 0, false
      end

      pdf.add_description_item Weakness.human_attribute_name(:audit_comments), weakness.audit_comments, 0, false

      if weakness.origination_date
        pdf.add_description_item Weakness.human_attribute_name(:origination_date), I18n.l(weakness.origination_date, format: :long), 0, false
      end

      audited = weakness.users.select &:can_act_as_audited?

      pdf.add_title I18n.t('finding.responsibles', count: audited.size), PDF_FONT_SIZE, :left
      pdf.add_list audited.map(&:full_name), PDF_FONT_SIZE * 2

      if weakness.finding_answers.present?
        column_names = [['answer', 50], ['user_id', 30], ['created_at', 20]]
        column_headers, column_widths, column_data = [], [], []

        column_names.each do |col_name, col_size|
          column_headers << FindingAnswer.human_attribute_name(col_name)
          column_widths  << pdf.percent_width(col_size)
        end

        weakness.finding_answers.each do |finding_answer|
          column_data << [
            finding_answer.answer,
            finding_answer.user.try(:full_name),
            I18n.l(finding_answer.created_at, format: :validation)
          ]
        end

        pdf.move_down PDF_FONT_SIZE

        pdf.add_title I18n.t('finding.follow_up_report.follow_up_comments'), (PDF_FONT_SIZE * 1.25).round

        pdf.move_down PDF_FONT_SIZE

        if column_data.present?
          pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
            table_options = pdf.default_table_options column_widths

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

    def add_filter_options_to_pdf pdf, report_params
      value_filter_names = %i(
        risk
        priority
        finding_status
        repeated
        compliance
        finding_current_situation_verified
        user_in_comments
        include_user_tree
      )
      filters            = []
      labels             = {
        review:                             Review.model_name.human,
        project:                            PlanItem.human_attribute_name('project'),
        process_control:                    ProcessControl.model_name.human,
        control_objective:                  ControlObjective.model_name.human,
        tags:                               Tag.model_name.human,
        user:                               User.model_name.human,
        user_in_comments:                   I18n.t('shared.filters.user.user_in_comments'),
        include_user_tree:                  I18n.t('shared.filters.user.include_user_tree'),
        finding_status:                     Weakness.human_attribute_name('state'),
        finding_title:                      Weakness.human_attribute_name('title'),
        risk:                               Weakness.human_attribute_name('risk'),
        priority:                           Weakness.human_attribute_name('priority'),
        finding_current_situation_verified: Weakness.human_attribute_name('current_situation_verified'),
        repeated:                           I18n.t('findings.state.repeated'),
        compliance:                         Weakness.human_attribute_name('compliance'),
        issue_date:                         ConclusionFinalReview.human_attribute_name('issue_date'),
        origination_date:                   Weakness.human_attribute_name('origination_date'),
        follow_up_date:                     Weakness.human_attribute_name('follow_up_date'),
        solution_date:                      Weakness.human_attribute_name('solution_date')
      }

      labels.each do |filter_name, filter_label|
        if report_params[filter_name].present?
          operator = report_params["#{filter_name}_operator"] || '='
          value = if value_filter_names.include? filter_name
                    weaknesses_report_value_to_label report_params, filter_name
                  elsif operator == 'between'
                    operator = I18n.t('shared.filters.date_field.between').downcase

                    [
                      report_params[filter_name],
                      report_params["#{filter_name}_until"]
                    ].reject(&:blank?).to_sentence
                  else
                    report_params[filter_name]
                  end

          filters << "<b>#{filter_label}</b> #{operator} #{value}"
        end
      end

      add_pdf_filters pdf, 'follow_up', filters if filters.present?
    end

    def weaknesses_report_value_to_label report_params, param_name
      value = report_params[param_name].to_i

      case param_name
      when :risk
        risk = Weakness.risks.detect { |r| r.last == value }

        risk ? I18n.t("risk_types.#{risk.first}") : ''
      when :priority
        priority = Weakness.priorities.detect { |p| p.last == value }

        priority ? I18n.t("priority_types.#{priority.first}") : ''
      when :finding_status
        I18n.t "findings.state.#{Finding::STATUS.invert[value]}"
      when :user_in_comments, :include_user_tree
        value == 1 ? I18n.t('label.yes') : I18n.t('label.no')
      when :finding_current_situation_verified
        I18n.t "label.#{report_params[param_name]}"
      when :repeated
        value = report_params[param_name] == 'true'

        value ? I18n.t('label.yes') : I18n.t('label.no')
      when :compliance
        value = report_params[param_name] == 'yes'

        value ? I18n.t('label.yes') : I18n.t('label.no')
      end
    end
  end
end
