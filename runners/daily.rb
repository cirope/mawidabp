Rails.logger.info "Starting daily runner (version #{APP_REVISION[0,8]})"

if Organization.any?
  User.notify_auditors_about_close_date

  Finding.notify_for_unconfirmed_for_notification_findings

  User.notify_new_findings

  Finding.mark_as_unanswered_if_necesary
  Finding.warning_users_about_expiration
  Finding.notify_manager_if_necesary
  Finding.send_brief

  Task.warning_users_about_expiration

  LdapConfig.sync_users
end

CarrierWave.clean_cached_files!

Rails.logger.info "Daily runner finished (version #{APP_REVISION[0,8]})"
