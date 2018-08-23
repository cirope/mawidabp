# Preview all emails at http://localhost:3000/rails/mailers/ldap_mailer
class LdapMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/ldap_mailer/import_notifier
  def import_notifier
    organization = Organization.take
    states       = %i(updated deleted created errored)
    imports      = organization.users.limit(10).map do |u|
      state  = states.sample
      errors = state == :errored ? ['Perfiles debe tener al menos uno'] : []

      { user: { name: u.to_s, errors: errors.to_sentence }, state: state }
    end

    LdapMailer.import_notifier(imports.to_json, organization.id)
  end
end
