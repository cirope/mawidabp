module LdapConfigs::Validation
  extend ActiveSupport::Concern

  included do
    attr_accessor :test_user, :test_password, :service_password

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
    validates :service_password, presence: true, if: ->(ldap) { ldap.service_user.present? }
    validate :can_connect?
  end

  private

    def can_connect?
      if service_user.present? && service_password.present?
        service_ldap = ldap(service_user, service_password)

        errors.add(:service_user, :invalid_credentials) unless service_ldap.bind
        return
      end

      if test_user.present? && test_password.present?
        test_ldap = ldap(test_user, test_password)

        return if test_ldap.bind
      end

      errors.add :base, I18n.t('message.ldap_error') # si no se "bindea" o no hay credenciales
    rescue
      errors.add :base, I18n.t('message.ldap_error')
    end
end
