Rails.logger.info "Starting weekly runner (version #{APP_REVISION[0,8]})"

if Organization.any?
  Finding.remember_users_about_expiration
  Finding.notify_expired_and_stale_follow_up
  Finding.remember_users_about_unanswered

  if USE_SCOPE_CYCLE && Date.today.between?(Date.current.beginning_of_month,
                                            (Date.current.beginning_of_month.weeks_since 1))
    Finding.notify_implemented_findings_with_follow_up_date_last_changed_greater_than_90_days
  end

  Task.remember_users_about_expiration
end

Rails.logger.info "Weekly runner finished (version #{APP_REVISION[0,8]})"
