module LdapConfigs::Ldap
  extend ActiveSupport::Concern

  def ldap username, password
    Net::LDAP.new ldap_options(username, password)
  end

  def mask_regex
    /\A#{login_mask % { user: '(.*)', basedn: Regexp.escape(basedn), ou: '(.*)' }}\z/
  end

  def unmasked_user username
    match = username.match mask_regex

    match ? match[1] : username
  end

  def alternative_ldap
    return unless try_alternative_ldap?

    @using_alternative_ldap = true

    dup.tap do |alternative|
      alternative.hostname = alternative.alternative_hostname
      alternative.port     = alternative.alternative_port
    end
  end

  def try_alternative_ldap?
    alternative_hostname.present? && @using_alternative_ldap.blank?
  end

  private

    def ldap_options username, password
      options = {
        host: hostname,
        port: port,
        auth: {
          method:   :simple,
          username: username_for(username),
          password: password
        }
      }

      if ca_path.present? && tls.present?
        options.merge(
          encryption: {
            method:      :simple_tls,
            tls_options: {
              ca_file:     ca_path,
              ssl_version: tls
            }
          }
        )
      else
        options
      end
    end

    def username_for username
      if username =~ mask_regex
        username
      else
        user = if Current.organization
                 Current.organization.users.find_by user: username
               else
                 User.find_by user: username
               end

        ou = user&.organizational_unit.presence || organizational_unit

        login_mask % { user: username, basedn: basedn, ou: ou }
      end
    end
end
