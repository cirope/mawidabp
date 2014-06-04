require 'digest/sha2'

module Users::Password
  extend ActiveSupport::Concern

  included do
    after_update :log_password_change

    has_many :old_passwords, dependent: :destroy
  end

  module ClassMethods
    def digest string, salt
      Digest::SHA512.hexdigest "#{salt}-#{string}"
    end
  end

  def encrypt_password
    self.salt ||= create_new_salt

    unless is_encrypted?
      self.password = User.digest password, salt
      self.password_was_encrypted = true
    end
  end

  def last_passwords
    limit = get_parameter(:password_count).to_i - 1

    old_passwords.order('created_at DESC').limit(limit > 0 ? limit : 0)
  end

  def reset_password! organization, notify = true
    self.change_password_hash = SecureRandom.urlsafe_base64
    self.hash_changed = Time.now

    Notifier.restore_password(self, organization).deliver if notify

    save!
  end

  def password_was_encrypted
    unless @_pwe_first_access
      @password_was_encrypted = false
      @_pwe_first_access = true
    end

    @password_was_encrypted
  end

  def password_was_encrypted= password_was_encrypted
    @_pwe_first_access = true

    @password_was_encrypted = password_was_encrypted
  end

  private

    def create_new_salt
      Digest::SHA512.hexdigest object_id.to_s + rand.to_s
    end

    def is_encrypted?
      password && password.length > 120 && password =~ /^(\d|[a-f])+$/
    end

    def log_password_change
      encrypt_password if password

      if password && password_was != password
        @last_passwords = nil
        old_passwords.create password: password_was
      end
    end
end
