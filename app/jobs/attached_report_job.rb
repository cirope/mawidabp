class AttachedReportJob < ApplicationJob
  queue_as :default

  def perform args
    model           = args.fetch(:model_name).constantize
    ids             = args.fetch(:ids)
    filename        = args.fetch(:filename)
    method_name     = args.fetch(:method_name)
    options         = args.fetch(:options, {})
    user_id         = args.fetch(:user_id)
    organization_id = args.fetch(:organization_id)

    report = model.where(id: ids).send method_name, options

    zip_file = zip_report_with_filename report, filename

    extension = File.extname filename
    new_filename = filename.sub(
      /#{Regexp.escape extension}$/,
      '.zip'
    )

    ReportMailer.attached_report(
      filename:        new_filename,
      file:            zip_file,
      user_id:         user_id,
      organization_id: organization_id
    ).deliver_later
  end

  private

    def zip_report_with_filename report, filename
      # In memory compression
      zip_io = Zip::OutputStream.write_buffer do |zip|
        zip.put_next_entry filename
        zip.write report
      end

      zip_io.rewind # reset IOfile read pointer
      zip_io.read
    end
end
