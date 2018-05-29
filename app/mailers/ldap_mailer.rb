class LdapMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper

  # helper :application, :notifier

  default from: "#{ENV['EMAIL_NAME'] || I18n.t('app_name')} <#{ENV['EMAIL_ADDRESS']}>"

  def import_notifier(imported_users)
    @users = {
      created:   [],
      updated:   [],
      deleted:   [],
      unchanged: []
    }
    imported_users.each do |d|
      @users[d[:status]] << d[:user] if d[:status] != :unchanged # no necesario
    end

    email = @organization.managers.map(&:email).join(', ')  # check scope
    subject = I18n.t(
      'ldap_mailer.import_notifier.subject',
      organization: @organization.prefix.upcase
    )

    mail to: email, subject: subject
  end
end
