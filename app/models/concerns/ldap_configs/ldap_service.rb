module LdapConfigs::LDAPService
  extend ActiveSupport::Concern

  included do
    before_save :encrypt_service_password!, if: ->(ldap) { ldap.service_password_unmasked.present? }

    scope :with_service_user, -> { where.not(service_password: nil) }
  end

  def encrypt_service_password!
    self.service_password = Security.encrypt(service_password_unmasked)
  end

  def decrypted_service_password
    Security.decrypt(service_password) if service_password.present?
  end
end
