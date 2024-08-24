require 'test_helper'

class SamlProvidersHelperTest < ActionView::TestCase
  test 'should return providers' do
    assert_equal providers,
                 SamlProvider::PROVIDERS.map { |p| [t("organizations.saml_providers.#{p}"), p] }
  end

  test 'should return default roles for organization' do
    organization = organizations :cirope

    assert_equal default_roles_for_users(organization),
                 Role.where(organization: organization).map { |r| [r.name, r.id] }
  end
end
