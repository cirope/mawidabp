ActionController::Renderers.add :rtf do |str, options|
  filename = options[:filename] || 'data'

  send_data str,
    type:        "#{Mime[:rtf]}; charset=utf-8",
    disposition: "attachment; filename=\"#{filename}.rtf\""
end
