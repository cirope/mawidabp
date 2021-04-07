class IdpSettingsAdapter
  def self.saml_settings(idp_entity_id)
    case idp_entity_id
    when config.azure[:idp_entity_id]
      return OneLogin::RubySaml::Settings.new config.azure
    else
      return OneLogin::RubySaml::Settings.new config.azure
    end
  end

  def self.get_idp_name(idp_entity_id)
    case idp_entity_id
    when config.azure[:idp_entity_id]
      return 'azure'
    else
      return 'azure'
    end
  end

  def self.get_idp_homepage(idp_entity_id)
    idp_name = self.get_idp_name(idp_entity_id)

    return eval("config.#{idp_name}[:idp_homepage]")
  end

  private

    def self.config
      OpenStruct.new Rails.application.credentials.identity_providers
    end
end
