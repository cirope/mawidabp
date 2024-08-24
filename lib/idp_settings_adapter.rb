class IdpSettingsAdapter
  def self.saml_settings saml_provider
    return OneLogin::RubySaml::Settings.new saml_provider_attributes(saml_provider)
  end

  def self.get_idp_homepage saml_provider
    return saml_provider_attributes(saml_provider)[:idp_homepage]
  end

  private

    def self.saml_provider_attributes saml_provider
      saml_provider.attributes
                   .symbolize_keys
                   .slice :idp_homepage, :idp_entity_id, :idp_sso_target_url,
                          :sp_entity_id, :assertion_consumer_service_url, :name_identifier_format,
                          :assertion_consumer_service_binding, :idp_cert
    end
end
