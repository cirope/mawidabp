module ConclusionDraftReviews::AppliedProcedures
  extend ActiveSupport::Concern

  def suggested_applied_procedures
    applied_procedures = []

    review.grouped_control_objective_items.each do |process_control, cois|
      cois.sort.each do |coi|
        applied_procedures << [
          coi.control.design_tests,
          coi.control.compliance_tests,
          coi.control.sustantive_tests
        ].reject(&:blank?).join("\n")
      end
    end

    applied_procedures.join "\n"
  end
end
