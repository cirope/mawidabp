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
    if Organization.current_id.present?
      @organization = Organization.find(Organization.current_id)
    end
    imported_users.each do |d|
      @organization ||= d[:user].organizations.first # ???? o se lo pasamos por paramentro?
      @users[d[:state]] << d[:user] if d[:state] != :unchanged # no necesario
    end

    email = @organization.users_with_roles(
      :supervisor, :manager
    ).pluck(:email)

    subject = I18n.t(
      'ldap_mailer.import_notifier.subject',
      organization: @organization.prefix.upcase
    )

    mail to: email, subject: subject
  end
end
