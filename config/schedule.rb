# Learn more: http://github.com/javan/whenever
#
# Para actualizar la tabla de cron de desarrollo:
# whenever --set environment=development --update-crontab mawidabp
# Para eliminarla
# whenever -c mawidabp

every 1.day, at: '20:00' do
  runner 'ConclusionFinalReview.warning_auditors_about_close_date'
  runner 'Finding.notify_for_unconfirmed_for_notification_findings'
  runner 'User.notify_new_findings'
  runner 'Finding.mark_as_unanswered_if_necesary'
  runner 'Finding.warning_users_about_expiration'
  runner 'Finding.notify_manager_if_necesary'
end
