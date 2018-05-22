module LdapConfigs::LDAPService
  extend ActiveSupport::Concern

  included do
    # attr_accessor :service_password
    before_save :encrypt_service_password, if: ->(ldap) { ldap.service_password.present? }

    scope :with_service_user, -> { where.not(encrypted_service_password: nil) }
  end

  def encrypt_service_password
    self.encrypted_service_password = Security.encrypt(service_password)
  end

  def decrypted_service_password
    Security.decrypt(encrypted_service_password) if encrypted_service_password.present?
  end
end
