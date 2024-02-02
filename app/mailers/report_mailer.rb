class ReportMailer < ApplicationMailer
  include ActionView::Helpers::TextHelper

  helper :markdown

  def attached_report kwargs
    @user        = User.find kwargs[:user_id]
    organization = Organization.find kwargs[:organization_id]

    attachments[kwargs[:filename]] = { mime_type: 'application/zip', content: File.read(kwargs[:file]) }

    mail(
      to: @user.email,
      subject: I18n.t('report_mailer.attached_report.subject', organization: organization.prefix.upcase)
    )
  end
end
