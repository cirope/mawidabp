module BestPractices::Csv
  extend ActiveSupport::Concern

  def to_csv
    options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

    csv_str = CSV.generate(**options) do |csv|
      csv << csv_headers

      csv_rows.each { |row| csv << row }
    end

    "\uFEFF#{csv_str}"
  end

  def csv_filename
    name.downcase.gsub('.', '').sanitized_for_filename[0..120]
  end

  private

    def csv_headers
      [
        ProcessControl.model_name.human,
        ControlObjective.human_attribute_name('name'),
        Control.human_attribute_name('control'),
        Control.human_attribute_name('design_tests'),
        (Control.human_attribute_name('compliance_tests') unless HIDE_CONTROL_COMPLIANCE_TESTS),
        Control.human_attribute_name('sustantive_tests'),
        (Control.human_attribute_name('effects') unless HIDE_CONTROL_EFFECTS),
        ControlObjective.human_attribute_name('risk'),
        ControlObjective.human_attribute_name('relevance'),
        ControlObjective.human_attribute_name('obsolete'),
        (ControlObjective.human_attribute_name('audit_sector') if show_gal_columns?),
        (ControlObjective.human_attribute_name('date_charge') if show_gal_columns?),
        (I18n.t('best_practice.auditors') if show_gal_columns?),
        (I18n.t('best_practice.audited') if show_gal_columns?),
        (Tag.model_name.human(count: 0) if show_gal_columns?),
        (Sector.model_name.human if show_gal_columns?)
      ].compact
    end

    def csv_rows
      rows = []

      process_controls.each do |process_control|
        process_control.control_objectives.each do |control_objective|

          if show_gal_columns?
            auditors, audited = control_objective&.control_objective_auditors.map { |u| u.user }.partition(&:auditor?)

            auditors = auditors.map { |u| u.full_name }.join(" ; ")
            audited = audited.map { |u| u.full_name }.join(" ; ")
          end

          rows << [
            process_control.name.to_s,
            control_objective.name.to_s,
            control_objective.control.control.to_s,
            control_objective.control.design_tests.to_s,
            (control_objective.control.compliance_tests.to_s unless HIDE_CONTROL_COMPLIANCE_TESTS),
            control_objective.control.sustantive_tests.to_s,
            (control_objective.control.effects.to_s unless HIDE_CONTROL_EFFECTS),
            control_objective.risk_text,
            control_objective.relevance_text,
            I18n.t(control_objective.obsolete ? 'label.yes' : 'label.no'),
            (control_objective.audit_sector.to_s if show_gal_columns?),
            (date_charge_format(control_objective) if show_gal_columns?),
            (auditors if show_gal_columns?),
            (audited if show_gal_columns?),
            (control_objective&.taggings.map(&:tag).join(' ; ') if show_gal_columns?),
            (control_objective&.affected_sector&.name if show_gal_columns?)
          ].compact
        end
      end

      rows
    end

    def date_charge_format control_objective
      control_objective.date_charge ? I18n.l(control_objective.date_charge, format: :minimal) : '-'
    end

    def show_gal_columns?
      Current.conclusion_pdf_format == 'gal'
    end
end
