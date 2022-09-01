module SamlProvidersHelper
  def providers
    SamlProvider::PROVIDERS.map { |p| [t("organizations.saml_providers.#{p}"), p] }
  end

  def default_roles_for_users organization
    Role.where(organization: organization).map { |r| [r.name, r.id] }
  end
end
