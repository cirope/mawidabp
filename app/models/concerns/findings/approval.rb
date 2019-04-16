module Findings::Approval
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
      audit_comments_error,
      task_error
    ].compact

    (@approval_errors = errors).blank?
  end

  private

    def solution_date_error
      if implemented_audited? && solution_date.blank?
        I18n.t "#{class_name}.errors.without_solution_date"
      elsif (implemented? || being_implemented?) && solution_date.present?
        I18n.t "#{class_name}.errors.with_solution_date"
      end
    end

    def follow_up_date_error
      if (implemented? || being_implemented?) && follow_up_date.blank?
        I18n.t "#{class_name}.errors.without_follow_up_date"
      elsif assumed_risk? && follow_up_date.present?
        I18n.t "#{class_name}.errors.with_follow_up_date"
      end
    end

    def answer_error
      check_blank = awaiting? ||
        being_implemented?    ||
        SHOW_WEAKNESS_EXTRA_ATTRIBUTES

      if check_blank && answer.blank?
        I18n.t "#{class_name}.errors.without_answer"
      end
    end

    def valid_state_error
      has_valid_state = implemented_audited? ||
        implemented?                         ||
        awaiting?                            ||
        being_implemented?                   ||
        unanswered?                          ||
        assumed_risk?                        ||
        criteria_mismatch?                   ||
        expired?

      unless has_valid_state
        I18n.t "#{class_name}.errors.not_valid_state"
      end
    end

    def audited_error
      unless has_audited?
        I18n.t "#{class_name}.errors.without_audited"
      end
    end

    def auditor_error
      unless has_auditor?
        I18n.t "#{class_name}.errors.without_auditor"
      end
    end

    def effect_error
      if kind_of?(Weakness) && !HIDE_WEAKNESS_EFFECT && effect.blank?
        I18n.t "#{class_name}.errors.without_effect"
      end
    end

    def audit_comments_error
      if audit_comments.blank? && !revoked? && Current.conclusion_pdf_format != 'gal'
        I18n.t "#{class_name}.errors.without_audit_comments"
      end
    end

    def task_error
      if tasks.any?(&:expired?)
        I18n.t "#{class_name}.errors.with_expired_tasks"
      end
    end

    def class_name
      self.class.name.downcase
    end
end
