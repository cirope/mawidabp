module LdapConfigs::LDAPService
  extend ActiveSupport::Concern

  included do
    scope :with_user, -> { where.not(user: nil, encrypted_password: nil) }
    before_save :encrypt_password, if: :password?
  end

  def encrypt_password
    self.encrypted_password = Security.encrypt(password)
  end

  def decrypted_password
    Security.decrypt(encrypted_password) if encrypted_password.present?
  end

  def sync
    import(user, decrypted_password)
  end

  module ClassMethods
    def sync_users
      all.with_user.preload(:organization).each do |ldap|
        puts "[#{ldap.organization.prefix.upcase}] Importing users for #{ldap.basedn}"
        ::Rails.logger.info(
          "[#{ldap.organization.prefix.upcase}] Importing users for #{ldap.basedn}"
        )

        begin
          imports = ldap.sync
          LdapMailer.import_notifier(imports, ldap.organization).deliver_later
        rescue ::StandardError=> e
          ::Rails.logger.error(e)
        end
      end
    end
  end

  private

    def password?
      password.present?
    end
end
