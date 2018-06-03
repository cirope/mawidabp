module LdapConfigs::LDAPService
  extend ActiveSupport::Concern

  included do
    scope :with_user, -> { where.not(user: ['', nil], encrypted_password: ['', nil]) }
    before_save :encrypt_password, if: :password?
  end

  def encrypt_password
    self.encrypted_password = Security.encrypt(password)
  end

  def decrypted_password
    Security.decrypt(encrypted_password) if encrypted_password.present?
  end

  def service_import
    import(user, decrypted_password)
  end

  private

    def password?
      password.present?
    end
end
