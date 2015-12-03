require 'csv'

ActionController::Renderers.add :csv do |str, options|
  filename = options[:filename] || 'data'

  send_data "\uFEFF" << str,
    type:        "#{Mime::CSV}; charset=utf-8",
    disposition: "attachment; filename=#{filename}.csv"
end
