module BestPractices::Csv
  extend ActiveSupport::Concern

  def to_csv
    options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

    csv_str = CSV.generate(options) do |csv|
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
        ControlObjective.human_attribute_name('risk')
      ].compact
    end

    def csv_rows
      rows = []

      process_controls.each do |process_control|
        process_control.control_objectives.each do |control_objective|
          rows << [
            process_control.name.to_s,
            control_objective.name.to_s,
            control_objective.control.control.to_s,
            control_objective.control.design_tests.to_s,
            (control_objective.control.compliance_tests.to_s unless HIDE_CONTROL_COMPLIANCE_TESTS),
            control_objective.control.sustantive_tests.to_s,
            (control_objective.control.effects.to_s unless HIDE_CONTROL_EFFECTS),
            control_objective.risk_text
          ].compact
        end
      end

      rows
    end
end
