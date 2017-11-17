module ControlObjectiveItems::Approval
  extend ActiveSupport::Concern

  included do
    attr_reader :approval_errors
  end

  def must_be_approved?
    @approval_errors = [
      not_finished_error,
      score_error,
      blank_attributes_errors,
      blank_control_attributes_errors,
      blank_score_errors
    ].compact.flatten

    @approval_errors.blank?
  end

  private

    def not_finished_error
      I18n.t 'control_objective_item.errors.not_finished' unless finished?
    end

    def score_error
      return if exclude_from_score || HIDE_CONTROL_OBJECTIVE_ITEM_EFFECTIVENESS

      if design_score.blank? && compliance_score.blank? && sustantive_score.blank?
        I18n.t 'control_objective_item.errors.without_score'
      end
    end

    def blank_attributes_errors
      errors = []

      if relevance.blank?
        errors << I18n.t('control_objective_item.errors.without_relevance')
      end

      if audit_date.blank?
        errors << I18n.t('control_objective_item.errors.without_audit_date')
      end

      if auditor_comment.blank?
        errors << I18n.t('control_objective_item.errors.without_auditor_comment')
      end

      errors
    end

    def blank_control_attributes_errors
      errors = []

      if control&.effects.blank? && !HIDE_CONTROL_EFFECTS
        errors << I18n.t('control_objective_item.errors.without_effects')
      end

      if control&.control.blank?
        errors << I18n.t('control_objective_item.errors.without_controls')
      end

      errors
    end

    def blank_score_errors
      return if HIDE_CONTROL_OBJECTIVE_ITEM_EFFECTIVENESS

      errors = []

      if design_score && control&.design_tests.blank?
        errors << I18n.t('control_objective_item.errors.without_design_tests')
      end

      if compliance_score && control&.compliance_tests.blank?
        errors << I18n.t('control_objective_item.errors.without_compliance_tests')
      end

      if sustantive_score && control&.sustantive_tests.blank?
        errors << I18n.t('control_objective_item.errors.without_sustantive_tests')
      end

      errors
    end
end
