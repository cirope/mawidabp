module LdapConfigs::LDAPService
  extend ActiveSupport::Concern

  included do
    before_save :encrypt_service_password!
  end

  def encrypt_service_password!
    return if service_password_unmasked.blank?

    self.service_password = Security.encrypt(service_password_unmasked)
  end

  def decrypted_service_password
    Security.decrypt(service_password) if service_password.present?
  end
end
