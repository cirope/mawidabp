class ReportMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper

  helper :markdown

  default from: "#{ENV['EMAIL_NAME'] || I18n.t('app_name')} <#{ENV['EMAIL_ADDRESS']}>"

  def zipped_csv(user, zipped_csv, filename, organization)
    @user = user

    attachments[filename] = { mime_type: 'application/zip', content: zipped_csv }

    mail(
      to: user.email,
      subject: I18n.t('report_mailer.csv.subject', organization: organization.prefix.upcase)
    )
  end
end
