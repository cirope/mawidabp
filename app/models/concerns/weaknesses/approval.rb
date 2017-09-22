module Weaknesses::Approval
  extend ActiveSupport::Concern

  included do
    attr_reader :approval_errors
  end

  def must_be_approved?
    return true if revoked? || criteria_mismatch?

    errors = [
      solution_date_error,
      follow_up_date_error,
      answer_error,
      valid_state_error,
      audited_error,
      auditor_error,
      effect_error,
      audit_comments_error
    ].compact

    (@approval_errors = errors).blank?
  end


  private

    def solution_date_error
      if implemented_audited? && solution_date.blank?
        I18n.t 'weakness.errors.without_solution_date'
      elsif (implemented? || being_implemented?) && solution_date.present?
        I18n.t 'weakness.errors.with_solution_date'
      end
    end

    def follow_up_date_error
      if (implemented? || being_implemented?) && follow_up_date.blank?
        I18n.t 'weakness.errors.without_follow_up_date'
      elsif assumed_risk? && follow_up_date.present?
        I18n.t 'weakness.errors.with_follow_up_date'
      end
    end

    def answer_error
      if being_implemented? && answer.blank?
        I18n.t 'weakness.errors.without_answer'
      end
    end

    def valid_state_error
      has_valid_state = implemented_audited? ||
        implemented?                         ||
        being_implemented?                   ||
        unanswered?                          ||
        assumed_risk?                        ||
        criteria_mismatch?

      I18n.t 'weakness.errors.not_valid_state' unless has_valid_state
    end

    def audited_error
      I18n.t 'weakness.errors.without_audited' unless has_audited?
    end

    def auditor_error
      I18n.t 'weakness.errors.without_auditor' unless has_auditor?
    end

    def effect_error
      I18n.t 'weakness.errors.without_effect' if effect.blank?
    end

    def audit_comments_error
      if audit_comments.blank? && !revoked?
        I18n.t 'weakness.errors.without_audit_comments'
      end
    end
end
