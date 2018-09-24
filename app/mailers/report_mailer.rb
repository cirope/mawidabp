class ReportMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper

  helper :markdown

  def csv(user, csv, filename, organization)
    @user = user

    attachments[filename] = { mime_type: Mime[:csv], content: csv }

    mail(
      to: user.email,
      subject: I18n.t('report_mailer.csv.subject', organization: organization.prefix.upcase)
    )
  end
end
