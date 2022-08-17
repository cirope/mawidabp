module SamlProvidersHelper
  def providers
    SamlProvider::PROVIDERS.map { |p| [t("organizations.saml_providers.#{p}"), p] }
  end
end
