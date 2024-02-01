BusinessTime::Config.work_week            = %w(mon tue wed thu fri)
BusinessTime::Config.beginning_of_workday = '00:00 am'
BusinessTime::Config.end_of_workday       = '23:59 pm'

holidays_file_path = "#{Rails.root}/db/holidays.txt"

File.foreach(holidays_file_path) do |line|
  BusinessTime::Config.holidays << Date.parse(line)
end if File.exist?(holidays_file_path)
