# Learn more: http://github.com/javan/whenever
#
# Para actualizar la tabla de cron de desarrollo:
# whenever --set environment=development --update-crontab mawidabp
# Para eliminarla
# whenever -c mawidabp

env :PATH, ENV['PATH']

every 1.day, at: '20:00' do
  methods = [
    'User.notify_auditors_about_close_date',
    'Finding.notify_for_unconfirmed_for_notification_findings',
    'User.notify_new_findings',
    'Finding.mark_as_unanswered_if_necesary',
    'Finding.warning_users_about_expiration',
    'Finding.notify_manager_if_necesary'
  ]

  runner methods.join('; ')
end

every :thursday, at: '20:00' do
  runner 'Finding.remember_users_about_expiration'
end
