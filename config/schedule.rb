# Learn more: http://github.com/javan/whenever
#
# Para actualizar la tabla de cron de desarrollo:
# whenever --set environment=development --update-crontab mawidabp
# Para eliminarla
# whenever -c mawidabp

env :PATH, ENV['PATH']

job_type :runner_file,  'cd :path && :runner_command -e :environment :task :output'

every 1.day, at: '20:00' do
  runner_file "runners/daily.rb"
end

every :thursday, at: '20:00' do
  runner_file 'runners/weekly.rb'
end
