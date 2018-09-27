class AttachedReportJob < ApplicationJob
  queue_as :default

  def perform(model_name:, ids:, user_id:, filename:, organization_id:, method_name:, options: {})
    report = model_name.constantize
      .where(id: ids)
      .send(method_name, options)

    # In memory compression
    zip_io = Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry filename
      zip.write report
    end
    zip_io.rewind # reset IOfile read pointer

    user = User.find(user_id)
    organization = Organization.find(organization_id)

    extension = File.extname(filename)
    new_filename = filename.sub(
      /#{Regexp.escape(extension)}$/,
      '.zip'
    )

    ReportMailer.attached_report(
      user,
      zip_io.read,
      new_filename,
      organization
    ).deliver_now
  end
end
