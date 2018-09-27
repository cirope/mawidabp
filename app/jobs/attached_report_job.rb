class AttachedReportJob < ApplicationJob
  queue_as :default

  def perform args
    model           = args[:model_name].constantize
    ids             = args[:ids]
    filename        = args[:filename]
    method_name     = args[:method_name]
    options         = args[:options] || {}
    user_id         = args[:user_id]
    organization_id = args[:organization_id]

    report = model.where(id: ids).send method_name, options

    # In memory compression
    zip_io = Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry filename
      zip.write report
    end
    zip_io.rewind # reset IOfile read pointer

    user = User.find user_id
    organization = Organization.find organization_id

    extension = File.extname filename
    new_filename = filename.sub(
      /#{Regexp.escape extension}$/,
      '.zip'
    )

    ReportMailer.attached_report(
      new_filename,
      zip_io.read,
      user,
      organization
    ).deliver_now
  end
end
