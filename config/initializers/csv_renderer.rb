require 'csv'

ActionController::Renderers.add :csv do |str, options|
  filename = options[:filename] || 'data'
  filename = if File.extname(filename).downcase == '.csv'
               filename
             else
               "#{filename}.csv"
             end

  send_data str,
    type:        "#{Mime[:csv]}; charset=utf-8",
    disposition: "attachment; filename=\"#{filename}\""
end
