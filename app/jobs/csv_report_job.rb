class CsvReportJob < ApplicationJob
  queue_as :default

  def perform(model_name:, ids:, user_id:, filename:, organization_id:, csv_options: {})
    csv = model_name.constantize
      .where(id: ids)
      .to_csv(csv_options)

    # In memory csv compression
    zip_io = Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry filename
      zip.write csv
    end
    zip_io.rewind # reset IOfile read pointer

    user = User.find(user_id)
    organization = Organization.find(organization_id)

    new_filename = filename.gsub(/\.csv$/, '.zip')

    ReportMailer.zipped_csv(
      user,
      zip_io.read,
      new_filename,
      organization
    ).deliver_now
  end
end
