ActionController::Renderers.add :csv do |str, options|
  filename = options[:filename] || 'data'

  send_data(
    str,
    :type => Mime::CSV,
    :disposition => "attachment; filename=#{filename}.csv"
  )
end
