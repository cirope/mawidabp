module Registrations::Persistence
  extend ActiveSupport::Concern

  def save
    return false unless valid?

    User.transaction do
      group = create_group
      org   = create_organization group
      user  = create_user org

      NotifierMailer.welcome_email(user).deliver_later

      user
    rescue ActiveRecord::RecordInvalid => e
      self.errors.add :base, e.message # aca deberiamos poner algo mas onda "contacte a soporte"
      raise ActiveRecord::Rollback
    end
  rescue ActiveRecord::Rollback
    false
  end

  private

    def create_group
      Group.create!(
        name:                    organization,
        admin_email:             email,
        description:             'Registro público',
        send_notification_email: false
      )
    end

    def create_organization group
      group.organizations.create!(
        name:        organization,
        prefix:      organization.parameterize,
        description: organization
      )
    end

    def create_user org
      user = User.new(
        user:      self.user,
        name:      self.name,
        last_name: self.last_name,
        email:     self.email,
        language:  self.language,
        enable:    true
      )

      user.organization_roles.build organization: org, role: org.roles.first
      user.save!
    end
end
