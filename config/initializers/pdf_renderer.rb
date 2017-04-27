ActionController::Renderers.add :pdf do |object, options|
  path     = object.to_pdf
  filename = object.respond_to?(:pdf_name) ? object.pdf_name : object.to_s
  response = send_file path,
    type:        :pdf,
    disposition: "attachment; filename=#{filename}.pdf"

  FileRemoveJob.set(wait: 15.minutes).perform_later path

  response
end
