module LdapConfigs::LDAPService
  extend ActiveSupport::Concern

  included do
    # attr_accessor :password
    before_save :encrypt_password, if: ->(ldap) { ldap.password.present? }

    scope :with_user, -> { where.not(encrypted_password: nil) }
  end

  def encrypt_password
    self.encrypted_password = Security.encrypt(password)
  end

  def decrypted_password
    Security.decrypt(encrypted_password) if encrypted_password.present?
  end
end
