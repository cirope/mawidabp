Rails.logger.info "Starting weekly runner (version #{APP_REVISION[0,8]})"

if Organization.any?
  Finding.remember_users_about_expiration
  Finding.notify_expired_and_stale_follow_up
  Finding.remember_users_about_unanswered

  Task.remember_users_about_expiration
end

Rails.logger.info "Weekly runner finished (version #{APP_REVISION[0,8]})"
