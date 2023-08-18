Rails.logger.info "Starting daily runner (version #{APP_REVISION[0,8]})"

if Organization.any?
  User.notify_auditors_about_close_date

  Finding.notify_for_unconfirmed_for_notification_findings

  User.notify_new_findings

  Finding.mark_as_unanswered_if_necesary
  Finding.warning_users_about_expiration
  Finding.notify_manager_if_necesary
  Finding.send_brief

  if USE_SCOPE_CYCLE && Date.today == Date.today.beginning_of_month
    Finding.notify_implemented_findings_with_follow_up_date_last_changed_greater_than_90_days
  end

  Task.warning_users_about_expiration

  LdapConfig.sync_users
end

CarrierWave.clean_cached_files!


def delete_file_or_directory path
  if File.directory? path
    FileUtils.rm_rf path
  else
    FileUtils.rm path
  end
end

root_directory = Rails.root
tmp_directory  = "#{root_directory}/uploads/tmp"

Dir.foreach(tmp_directory) do |file_name|
  next if %w(. ..).include? file_name

  file_path = File.join tmp_directory, file_name

  delete_file_or_directory file_path if File.mtime(file_path) < 1.day.ago
end

Rails.logger.info "Daily runner finished (version #{APP_REVISION[0,8]})"
