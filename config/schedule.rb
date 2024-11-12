# Learn more: http://github.com/javan/whenever
#
# Para actualizar la tabla de cron de desarrollo:
# whenever --set environment=development --update-crontab mawidabp
# Para eliminarla
# whenever -c mawidabp

env :PATH, ENV['PATH']

job_type :runner_file, 'cd :path && :runner_command -e :environment :task :output'

every 5.minutes do
  runner_file 'runners/every_5_minutes.rb'
end

every 1.day, at: '08:00' do
  runner_file 'runners/daily.rb'
end

every :tuesday, at: '08:00' do
  runner_file 'runners/weekly.rb'
end

every 1.day, at: '03:00' do
  rake 'licenses:check_subscriptions'
end

every 1.hour do
  rake 'licenses:process_webhooks'
end
