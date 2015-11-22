require 'csv'

ActionController::Renderers.add :csv do |str, options|
  filename = options[:filename] || 'data'

  send_data "\uFEFF" << str,
    type:        Mime::CSV,
    disposition: "attachment; filename=#{filename}.csv"
end
