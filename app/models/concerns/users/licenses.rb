# frozen_string_literal: true
module Users::Licenses
  extend ActiveSupport::Concern

  included do
    before_save :check_auditors_limit_on_role_or_enable_change, if: :check_auditors_limit?
  end

  private

    def check_auditors_limit?
      new_record? || roles_has_changed? || enable_changed?
    end

    def check_auditors_limit_on_role_or_enable_change
      if adding_new_auditor? && !Current.group.can_create_auditor?
        Rails.logger.info "Group auditors limit reached (#{Current.group.auditors_limit})"
        errors.add :base, :auditors_limit_reached

        throw :abort
      end
    end

    def adding_new_auditor?
      old_user = User.find id unless new_record?

      organization_roles.reject(&:marked_for_destruction?).any? do |organization_role|
        audited = if new_record?
                    true
                  elsif enable_changed?
                    !old_user.enable
                  else
                    old_user.can_act_as_audited? organization_role.organization_id
                  end

        audited && Role::ACT_AS[:auditor].include?(organization_role.role.role_type)
      end
    end
end
