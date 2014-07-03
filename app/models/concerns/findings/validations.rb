module Findings::Validations
  extend ActiveSupport::Concern

  included do
    validates :control_objective_item_id, :description, :review_code, :organization_id, presence: true
    validates :review_code, length: { maximum: 255 }, allow_blank: true
    validates :audit_comments, presence: true, if: :revoked?
    validates :follow_up_date, :solution_date, :origination_date, :first_notification_date,
      timeliness: { type: :date }, allow_blank: true
    validate :validate_answer
    validate :validate_state
    validate :validate_review_code
    validate :validate_finding_user_assignments
    validate :validate_follow_up_date, if: :check_dates?
    validate :validate_solution_date,  if: :check_dates?
  end

  private

    def check_dates?
      !incomplete? && !revoked? && !repeated?
    end

    def validate_follow_up_date
      if kind_of?(Weakness) || kind_of?(Nonconformity)
        check_for_blank = being_implemented? || implemented? || implemented_audited?

        errors.add :follow_up_date, :blank         if check_for_blank  && follow_up_date.blank?
        errors.add :follow_up_date, :must_be_blank if !check_for_blank && follow_up_date.present?
      end
    end

    def validate_solution_date
      check_for_blank = implemented_audited? || assumed_risk?

      errors.add :solution_date, :blank         if check_for_blank  && solution_date.blank?
      errors.add :solution_date, :must_be_blank if !check_for_blank && solution_date.present?
    end

    def validate_answer
      check_for_blank = being_implemented? || (state_changed? && state_was == Finding::STATUS[:confirmed])

      errors.add :answer, :blank if check_for_blank && answer.blank?
    end

    def validate_state
      if state && state_changed? && next_status_list(state_was).values.exclude?(state)
        errors.add :state, :inclusion
      end

      errors.add :state, :must_have_a_comment if must_have_a_comment?
      errors.add :state, :can_not_be_revoked  if can_not_be_revoked?

      if implemented_audited? && work_papers.empty?
        errors.add :state, :must_have_a_work_paper
      end

      # No puede marcarse como repetida si no está en un informe definitivo
      if state && state_changed? && repeated?
        errors.add :state, :invalid unless is_in_a_final_review?
      end

      if revoked? && is_in_a_final_review?
        errors.add :state, :invalid
      end
    end

    def validate_review_code
      review = control_objective_item.try(:review)

      if review
        findings_for(review).each do |finding|
          another_record = (persisted? && finding.id != id) ||
                           (new_record? && finding.object_id != object_id)

          if review_code == finding.review_code && another_record && final == finding.final
            errors.add :review_code, :taken
          end
        end
      end
    end

    def findings_for review
      review.weaknesses | review.oportunities | review.fortresses |
        review.nonconformities | review.potential_nonconformities
    end

    def validate_finding_user_assignments
      users = finding_user_assignments.reject(&:marked_for_destruction?).map(&:user)

      unless users.any?(&:can_act_as_audited?) && users.any?(&:auditor?) && users.any?(&:supervisor?)
        errors.add :finding_user_assignments, :invalid
      end
    end
end
