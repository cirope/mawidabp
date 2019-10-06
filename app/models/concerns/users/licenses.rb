# frozen_string_literal: true
module Users::Licenses
  extend ActiveSupport::Concern

  included do
    before_save :check_auditors_limit_on_role_change, if: :check_auditors_limit?
  end

  private

    def check_auditors_limit?
      new_record? || roles_has_changed?
    end

    def check_auditors_limit_on_role_change
      if adding_new_auditor? && !Current.group.can_create_auditor?
        Rails.logger.info "Group auditors limit reached (#{Current.group.auditors_limit})"
        errors.add :base, :auditors_limit_reached

        throw :abort
      end
    end

    def adding_new_auditor?
      old_user = nil

      organization_roles.reject(&:marked_for_destruction?).any? do |organization_role|
        audited = if new_record?
                    true
                  else
                    old_user ||= User.find id

                    old_user.can_act_as_audited_on? organization_role.organization_id
                  end

        audited && Role::ACT_AS[:auditor].include?(organization_role.role.role_type)
      end
    end
end
