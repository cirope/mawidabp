class ReportMailer < ApplicationMailer
  include ActionView::Helpers::TextHelper

  helper :markdown

  def attached_report filename:, file:, user_id:, organization_id:
    @user = User.find user_id
    organization = Organization.find organization_id

    attachments[filename] = { mime_type: 'application/zip', content: File.read(file) }

    mail(
      to: @user.email,
      subject: I18n.t('report_mailer.attached_report.subject', organization: organization.prefix.upcase)
    )
  end
end
