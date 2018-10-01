class ReportMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper

  helper :markdown

  default from: "#{ENV['EMAIL_NAME'] || I18n.t('app_name')} <#{ENV['EMAIL_ADDRESS']}>"

  def attached_report filename:, file:, user_id:, organization_id:
    @user = User.find user_id
    organization = Organization.find organization_id

    attachments[filename] = { mime_type: 'application/zip', content: file }

    mail(
      to: @user.email,
      subject: I18n.t('report_mailer.csv.subject', organization: organization.prefix.upcase)
    )
  end
end
