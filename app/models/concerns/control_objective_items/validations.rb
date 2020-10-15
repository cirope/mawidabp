module ControlObjectiveItems::Validations
  extend ActiveSupport::Concern

  included do
    attr_accessor :creating_final_review

    ##before_validation :

    validates :control_objective_text, :control_objective_id,
      :organization_id, presence: true
    validates :control_objective_text, :auditor_comment, pdf_encoding: true
    validates :relevance, :issues_count, :alerts_count, numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 2147483647
    }, allow_blank: true, allow_nil: true
    validates :design_score, :compliance_score, :sustantive_score, numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100
    }, allow_blank: true, allow_nil: true
    validates :audit_date, timeliness: { type: :date }, allow_blank: true
    validates :audit_date, presence: true, if: :require_audit_date?
    validates :relevance, :auditor_comment, presence: true, if: :finished
    validates :auditor_comment, presence: true, if: :exclude_from_score
    validates :issues_count, :alerts_count, presence: true, if: :validate_counts?
    validate :audit_date_is_on_period
    validate :control_objective_uniqueness
    validate :tests_completion
    validate :score_with_test_completion
  end

  private

    def audit_date_is_on_period
      if validate_on_period?
        period = review&.period

        if period && audit_date && !audit_date.between?(period.start, period.end)
          errors.add :audit_date, :out_of_period
        end
      end
    end

    def validate_on_period?
      !(DISABLE_COI_AUDIT_DATE_VALIDATION && creating_final_review)
    end

    def control_objective_uniqueness
      return if ALLOW_REVIEW_CONTROL_OBJECTIVE_DUPLICATION

      is_duplicated = review && review.control_objective_items.any? do |coi|
        is_same        = coi.control_objective_id == control_objective_id
        another_record = (persisted? && coi.id != id) ||
                         (new_record? && coi.object_id != object_id)

        is_same && another_record && !coi.marked_for_destruction?
      end

      errors.add :control_objective_id, :taken if is_duplicated
    end

    def tests_completion
      if finished && !exclude_from_score
        all_blank = control.design_tests.blank?     &&
                    control.compliance_tests.blank? &&
                    control.sustantive_tests.blank?

        if all_blank
          control.errors.add :design_tests,     :blank
          control.errors.add :compliance_tests, :blank
          control.errors.add :sustantive_tests, :blank
        end
      end
    end

    def score_with_test_completion
      if finished && !exclude_from_score
        if design_score.blank? && control.design_tests.present?
          errors.add :design_score, :blank
        end

        if compliance_score.blank? && control.compliance_tests.present?
          errors.add :compliance_score, :blank
        end

        if sustantive_score.blank? && control.sustantive_tests.present?
          errors.add :sustantive_score, :blank
        end
      end
    end

    def require_audit_date?
      finished && !DISABLE_COI_AUDIT_DATE_VALIDATION
    end

    def validate_counts?
      finished && show_counts?(Current.organization.prefix)
    end
end
