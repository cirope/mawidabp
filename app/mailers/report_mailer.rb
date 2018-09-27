class ReportMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper

  helper :markdown

  default from: "#{ENV['EMAIL_NAME'] || I18n.t('app_name')} <#{ENV['EMAIL_ADDRESS']}>"

  def attached_report(user, zipped_report, filename, organization)
    @user = user

    attachments[filename] = { mime_type: 'application/zip', content: zipped_report }

    mail(
      to: user.email,
      subject: I18n.t('report_mailer.csv.subject', organization: organization.prefix.upcase)
    )
  end
end
