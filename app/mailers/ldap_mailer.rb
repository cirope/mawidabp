class LdapMailer < ApplicationMailer
  include ActionView::Helpers::TextHelper

  helper :markdown

  def import_notifier(imported_users_json, organization_id)
    @users = {
      created: [],
      deleted: [],
      errored: [],
      updated: []
    }

    organization = Organization.find(organization_id)
    imported_users = JSON.parse(imported_users_json)

    imported_users.each do |d|
      @users[d['state'].to_sym] << d['user']
    end
    @users.reject! { |_k, v| v.empty? }

    emails = organization.users_with_roles(:supervisor, :manager).pluck(:email)
    subject = I18n.t(
      'ldap_mailer.import_notifier.subject',
      organization: organization.prefix.upcase
    )

    mail to: emails, subject: subject
  end
end
