module LdapConfigs::Validation
  extend ActiveSupport::Concern

  included do
    attr_accessor :test_user, :test_password, :password

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
    validates :password, presence: true, if: ->(ldap) { ldap.user.present? }
    validate :can_connect?
  end

  private

    def can_connect?
      if user.present? && password.present?
        service_ldap = ldap(user, password)

        errors.add(:user, :invalid_credentials) unless service_ldap.bind
      else
        test_ldap = ldap(test_user, test_password)

        errors.add :base, I18n.t('message.ldap_error') unless test_ldap.bind
      end
    rescue
      errors.add :base, I18n.t('message.ldap_error')
    end
end
