require 'csv'

ActionController::Renderers.add :csv do |str, options|
  filename = options[:filename] || 'data'

  send_data str,
    type:        "#{Mime[:csv]}; charset=utf-8",
    disposition: "attachment; filename=\"#{filename}.csv\""
end
