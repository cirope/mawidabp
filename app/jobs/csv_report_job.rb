class CsvReportJob < ApplicationJob
  queue_as :default

  def perform(model_name:, ids:, user_id:, filename:, organization_id:, csv_options: {})
    csv = model_name.constantize
      .where(id: ids)
      .to_csv(csv_options)

    user = User.find(user_id)
    organization = Organization.find(organization_id)

    ReportMailer.csv(
      user,
      csv,
      filename,
      organization
    ).deliver_now
  end
end
