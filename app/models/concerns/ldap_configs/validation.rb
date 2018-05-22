module LdapConfigs::Validation
  extend ActiveSupport::Concern

  included do
    attr_accessor :test_user, :test_password, :service_password_unmasked

    validates :test_user, :test_password, :hostname, :port, :basedn, :filter,
      :login_mask, :username_attribute, :name_attribute,
      :last_name_attribute, :email_attribute, :roles_attribute,
      presence: true
    validates :hostname, :basedn, :filter, :login_mask, :username_attribute,
      :name_attribute, :last_name_attribute, :email_attribute,
      :roles_attribute, length: { maximum: 255 }
    validates :port, numericality: { only_integer: true, greater_than: 0, less_than: 65536 }
    validates :basedn, format: /\A(\w+=[\w-]+)(,\w+=[\w-]+)*\z/
    validates :username_attribute, :name_attribute, :last_name_attribute,
      :email_attribute, :function_attribute, :roles_attribute,
      :manager_attribute, format: /\A\w+\z/, allow_blank: true
    validates :service_password_unmasked, presence: true, if: ->(ldap) { ldap.service_user.present? }
    validate :can_connect?
  end

  private

    def can_connect?
      ldap = ldap test_user, test_password

      unless ldap.bind
        errors.add :base, I18n.t('message.ldap_error')
        return
      end

      if service_user.present? && service_password_unmasked.present?
        ldap = ldap(service_user, service_password_unmasked)

        errors.add(:service_user, :invalid_credentials) unless ldap.bind
      end
    rescue
      errors.add :base, I18n.t('message.ldap_error')
    end
end
