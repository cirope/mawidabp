# Learn more: http://github.com/javan/whenever
# 
# Para actualizar la tabla de cron de desarrollo:
# whenever --update-crontab --set environment=development

every 1.day, :at => '00:00' do
  runner 'Finding.notify_for_unconfirmed_for_notification_findings'
  runner 'User.notify_new_findings'
  runner 'Finding.mark_as_unanswered_if_necesary'
  runner 'Finding.warning_users_about_expiration'
end