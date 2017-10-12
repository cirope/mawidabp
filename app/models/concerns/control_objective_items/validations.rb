module ControlObjectiveItems::Validations
  extend ActiveSupport::Concern

  included do
    validates :control_objective_text, :control_objective_id,
      :organization_id, presence: true
    validates :control_objective_text, :auditor_comment, pdf_encoding: true
    validates :relevance, numericality: {
      only_integer: true, greater_than_or_equal_to: 0
    }, allow_blank: true, allow_nil: true
    validates :audit_date, timeliness: { type: :date }, allow_nil: true
    validates :audit_date, :relevance, :auditor_comment, presence: true, if: :finished
    validates :auditor_comment, presence: true, if: :exclude_from_score
    validate :audit_date_is_on_period
    validate :control_objective_uniqueness
    validate :score_completion
  end

  private

    def audit_date_is_on_period
      period = review&.period

      if period && audit_date && !audit_date.between?(period.start, period.end)
        errors.add :audit_date, :out_of_period
      end
    end

    def control_objective_uniqueness
      is_duplicated = review && review.control_objective_items.any? do |coi|
        is_same        = coi.control_objective_id == control_objective_id
        another_record = (persisted? && coi.id != id) ||
                         (new_record? && coi.object_id != object_id)

        is_same && another_record && !marked_for_destruction?
      end

      errors.add :control_objective_id, :taken if is_duplicated
    end

    def score_completion
      if finished && !exclude_from_score && !HIDE_CONTROL_OBJECTIVE_ITEM_EFFECTIVENESS
        if design_score.blank? && compliance_score.blank? && sustantive_score.blank?
          errors.add :design_score,     :blank
          errors.add :compliance_score, :blank
          errors.add :sustantive_score, :blank
        end
      end
    end
end
