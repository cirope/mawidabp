# frozen_string_literal: true

module Registrations::Persistence
  extend ActiveSupport::Concern

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      create_group
      create_organization
      create_license

      self.user = create_user

      NotifierMailer.welcome_email(user).deliver_later

      user
    rescue ActiveRecord::RecordInvalid => ex
      ::Rails.logger.error ex

      errors.add :base, ex.message

      raise ActiveRecord::Rollback
    end
  rescue ActiveRecord::Rollback
    false
  end

  private

    def create_group
      Current.group = Group.create!(
        name:                    organization_name,
        admin_email:             email,
        description:             organization_name,
        send_notification_email: false,
        licensed:                true
      )
    end

    def create_organization
      Current.organization = Current.group.organizations.create!(
        name:        organization_name,
        prefix:      organization_name.parameterize,
        description: organization_name
      )
    end

    def create_license
      Current.group.create_license! auditors_limit: 1
    end

    def create_user
      user = User.new(
        user:      self.user,
        name:      self.name,
        last_name: self.last_name,
        email:     self.email,
        language:  'es',
        enable:    true
      )

      user.organization_roles.build(
        organization: Current.organization,
        role:         Current.organization.roles.admin
      )

      user.save! && user
    end
end
