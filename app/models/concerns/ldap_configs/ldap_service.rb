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
      with_user.preload(:organization).each do |ldap|
        organization = ldap.organization

        Organization.current_id = organization.id # Roles scope

        ::Rails.logger.info(
          "[#{organization.prefix.upcase}] Importing users for #{ldap.basedn}"
        )

        imports = ldap.sync
        filtered_imports = imports.map do |i|
          unless i[:state] == :unchanged
            { user: { name: i[:user].to_s, errors: i[:errors] }, state: i[:state] }
          end
        end.compact

        if filtered_imports.any?
          LdapMailer.import_notifier(filtered_imports.to_json, organization.id).deliver_later
        end
      end

      Organization.current_id = nil
    end
  end

  private

    def password?
      password.present?
    end
end
