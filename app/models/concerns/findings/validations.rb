module Findings::Validations
  extend ActiveSupport::Concern

  included do
    attr_accessor :skip_work_paper

    validates :control_objective_item_id, :title, :description, :review_code,
      :organization_id, presence: true
    validates :review_code, :title, length: { maximum: 255 }, allow_blank: true
    validates :audit_comments, presence: true, if: :audit_comments_should_be_present?
    validates :review_code, :description, :answer, :audit_recommendations,
      :effect, :audit_comments, :title, :current_situation, :compliance,
      pdf_encoding: true
    validates :follow_up_date, :solution_date, :origination_date,
      :first_notification_date, timeliness: { type: :date }, allow_blank: true
    validate :validate_answer
    validate :validate_state
    validate :validate_review_code
    validate :validate_finding_user_assignments
    validate :validate_follow_up_date, if: :check_dates?
    validate :validate_solution_date,  if: :check_dates?
  end

  def is_in_a_final_review?
    control_objective_item&.review&.has_final_review?
  end

  def must_have_a_comment?
    has_new_comment = comments.detect { |c| c.new_record? && c.valid? }
    to_implemented  = implemented? && (was_implemented_audited? || was_expired?)
    to_pending      = (being_implemented? || awaiting?) &&
      (was_implemented_audited? || was_implemented? || was_assumed_risk? || was_expired?)

    (to_pending || to_implemented) && !has_new_comment
  end

  private

    def audit_comments_should_be_present?
      revoked? || criteria_mismatch?
    end

    def check_dates?
      !incomplete? && !revoked? && !repeated?
    end

    def validate_follow_up_date
      if kind_of?(Weakness)
        check_for_blank = awaiting?          ||
                          being_implemented? ||
                          implemented?       ||
                          implemented_audited?

        errors.add :follow_up_date, :blank         if check_for_blank  && follow_up_date.blank?
        errors.add :follow_up_date, :must_be_blank if !check_for_blank && follow_up_date.present?
      end
    end

    def validate_solution_date
      check_for_blank = implemented_audited? ||
                        assumed_risk?        ||
                        criteria_mismatch?   ||
                        expired?

      errors.add :solution_date, :blank         if check_for_blank  && solution_date.blank?
      errors.add :solution_date, :must_be_blank if !check_for_blank && solution_date.present?
    end

    def validate_answer
      check_for_blank = being_implemented? || (state_changed? && state_was == Finding::STATUS[:confirmed])

      errors.add :answer, :blank if check_for_blank && answer.blank?
    end

    def validate_state
      errors.add :state, :must_have_a_comment if must_have_a_comment?
      errors.add :state, :can_not_be_revoked  if can_not_be_revoked?

      validate_state_work_paper_presence
      validate_state_revocation
      validate_state_transition
      validate_state_repetition
      validate_state_user_if_final
    end

    def validate_state_work_paper_presence
      if implemented_audited? && work_papers.empty? && !skip_work_paper
        errors.add :state, :must_have_a_work_paper
      end
    end

    def validate_state_revocation
      errors.add :state, :invalid if revoked? && is_in_a_final_review?
    end

    def validate_state_transition
      if state && state_changed? && next_status_list(state_was).values.exclude?(state)
        errors.add :state, :inclusion
      end
    end

    def validate_state_repetition
      # No puede marcarse como repetida si no está en un informe definitivo
      if state && state_changed? && repeated? && !is_in_a_final_review?
        errors.add :state, :invalid
      end
    end

    def validate_state_user_if_final
      skip_validation = DISABLE_FINDING_FINAL_STATE_ROLE_VALIDATION ||
        (new_record? && final) # comes from a final review _clone_

      if !skip_validation && state && state_changed? && state.presence_in(Finding::FINAL_STATUS)
        has_role_to_do_it = Current.user.try(:supervisor?) || Current.user.try(:manager?)

        errors.add :state, :must_be_done_by_proper_role unless has_role_to_do_it
      end
    end

    def validate_review_code
      review = control_objective_item.try(:review)

      if review
        findings_for(review).each do |f|
          if review_code == f.review_code && not_equal_to(f) && final == f.final
            errors.add :review_code, :taken
          end
        end
      end
    end

    def not_equal_to finding
      (persisted? && finding.id != id) || (new_record? && finding.object_id != object_id)
    end

    def findings_for review
      review.weaknesses | review.oportunities
    end

    def validate_finding_user_assignments
      users = finding_user_assignments.reject(&:marked_for_destruction?).map &:user

      unless all_roles_fullfilled_by? users.compact
        errors.add :finding_user_assignments, :invalid
      end
    end

    def all_roles_fullfilled_by? users
      has_audited    = users.any? { |u| u.can_act_as_audited? || u.can_act_as_audited_on?(organization_id) }
      has_auditor    = users.any? { |u| u.auditor?            || u.auditor_on?(organization_id) }
      has_supervisor = users.any? { |u| u.supervisor?         || u.supervisor_on?(organization_id) }
      has_manager    = users.any? { |u| u.manager?            || u.manager_on?(organization_id) }

      has_audited && has_auditor && (has_supervisor || has_manager)
    end

    def can_not_be_revoked?
      revoked? && state_changed? && (repeated_of || is_in_a_final_review?)
    end
end
