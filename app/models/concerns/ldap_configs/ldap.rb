module LdapConfigs::Ldap
  extend ActiveSupport::Concern

  def ldap username, password
    Net::LDAP.new host: hostname, port: port, auth: {
      method:   :simple,
      username: username_for(username),
      password: password
    }
  end

  def mask_regex
    /\A#{login_mask % { user: '(.*)', basedn: Regexp.escape(basedn) }}\z/
  end

  def unmasked_user username
    match = username.match mask_regex

    match ? match[1] : username
  end

  def alternative_ldap
    return unless try_alternative_ldap?

    @alternative_ldap = true

    dup.tap do |alternative|
      alternative.hostname = alternative.alternative_hostname
      alternative.port     = alternative.alternative_port
    end
  end

  def try_alternative_ldap?
    alternative_hostname.present? && @alternative_ldap.nil?
  end

  private

    def username_for username
      if username =~ mask_regex
        username
      else
        login_mask % { user: username, basedn: basedn }
      end
    end
end
