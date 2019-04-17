module Users::Authorization
  extend ActiveSupport::Concern

  def is_enable?
    enable? && Current.organization && !expired?
  end

  def is_group_admin?
    group_admin && enable
  end

  def expired?
    last_access.present? && last_access < get_parameter(:account_expire_time).to_i.days.ago
  end

  def password_expired?
    password_changed.to_time < get_parameter(:password_expire_time).to_i.days.ago
  end

  def first_login?
    last_access.blank? || last_access_was.blank?
  end

  def must_change_the_password?
    is_enable? && (password_expired? || first_login?)
  end

  def confirmation_hash
    change_password_hash unless must_change_the_password?
  end

  def days_for_password_expiration
    if warn_about_password_expiration?
      ((password_changed_time - password_expire_time.days.ago) / 1.day).round
    end
  end

  def allow_concurrent_access?
    revoke_concurrent_sessions? ? !has_a_current_session? : true
  end

  def logged_in! time = Time.zone.now
    self.is_an_important_change = false
    self.failed_attempts = 0
    self.logged_in = true
    self.last_access = time unless first_login?

    save validate: false
  end

  def logout!
    self.is_an_important_change = false

    update_column :logged_in, false
  end

  private

    def warn_about_password_expiration?
      expire_notification != 0 &&
        password_expire_time != 0 &&
        password_changed_time < expire_notification.days.ago
    end

    def expire_notification
      get_parameter(:expire_notification).to_i
    end

    def password_changed_time
      password_changed.to_time
    end

    def password_expire_time
      get_parameter(:password_expire_time).to_i
    end

    def session_expire_time
      get_parameter(:session_expire_time).to_i
    end

    def revoke_concurrent_sessions?
      get_parameter_for_now(:allow_concurrent_sessions).to_i == 0
    end

    def has_a_current_session?
      logged_in? &&
        (session_expire_time == 0 || last_access > session_expire_time.minutes.ago)
    end
end
