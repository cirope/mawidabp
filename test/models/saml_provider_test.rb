require 'test_helper'

class SamlProviderTest < ActiveSupport::TestCase
  setup do
    organization   = organizations :cirope
    @saml_provider = SamlProvider.new provider: 'azure',
                                      idp_homepage: 'https://login.microsoftonline.com/test/federationmetadata/2007-06/federationmetadata.xml',
                                      idp_entity_id: 'https://sts.windows.net/test/',
                                      idp_sso_target_url: 'https://login.microsoftonline.com/test/saml2',
                                      sp_entity_id: 'https://test.com/saml/metadata',
                                      assertion_consumer_service_url: 'https://test.com/saml/callback',
                                      name_identifier_format: 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
                                      assertion_consumer_service_binding: 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
                                      idp_cert: 'cert_test',
                                      organization: organization
  end

  test 'invalid when provider is not including in providers' do
    @saml_provider.provider = 'test'

    refute @saml_provider.valid?
    assert_error @saml_provider, :provider, :inclusion
  end

  test 'invalid when attributtes are blank' do
    @saml_provider.idp_homepage                       = ''
    @saml_provider.idp_entity_id                      = ''
    @saml_provider.idp_sso_target_url                 = ''
    @saml_provider.sp_entity_id                       = ''
    @saml_provider.assertion_consumer_service_url     = ''
    @saml_provider.name_identifier_format             = ''
    @saml_provider.assertion_consumer_service_binding = ''
    @saml_provider.idp_cert                           = ''
    @saml_provider.organization                       = nil

    refute @saml_provider.valid?
    assert_error @saml_provider, :idp_homepage, :blank
    assert_error @saml_provider, :idp_entity_id, :blank
    assert_error @saml_provider, :idp_sso_target_url, :blank
    assert_error @saml_provider, :sp_entity_id, :blank
    assert_error @saml_provider, :assertion_consumer_service_url, :blank
    assert_error @saml_provider, :name_identifier_format, :blank
    assert_error @saml_provider, :assertion_consumer_service_binding, :blank
    assert_error @saml_provider, :idp_cert, :blank
    assert_error @saml_provider, :organization, :blank

    @saml_provider.idp_homepage                       = nil
    @saml_provider.idp_entity_id                      = nil
    @saml_provider.idp_sso_target_url                 = nil
    @saml_provider.sp_entity_id                       = nil
    @saml_provider.assertion_consumer_service_url     = nil
    @saml_provider.name_identifier_format             = nil
    @saml_provider.assertion_consumer_service_binding = nil
    @saml_provider.idp_cert                           = nil

    refute @saml_provider.valid?
    assert_error @saml_provider, :idp_homepage, :blank
    assert_error @saml_provider, :idp_entity_id, :blank
    assert_error @saml_provider, :idp_sso_target_url, :blank
    assert_error @saml_provider, :sp_entity_id, :blank
    assert_error @saml_provider, :assertion_consumer_service_url, :blank
    assert_error @saml_provider, :name_identifier_format, :blank
    assert_error @saml_provider, :assertion_consumer_service_binding, :blank
    assert_error @saml_provider, :idp_cert, :blank
  end

  test 'invalid when attributtes are too long' do
    @saml_provider.idp_homepage                       = 'a' * 256
    @saml_provider.idp_entity_id                      = 'a' * 256
    @saml_provider.idp_sso_target_url                 = 'a' * 256
    @saml_provider.sp_entity_id                       = 'a' * 256
    @saml_provider.assertion_consumer_service_url     = 'a' * 256
    @saml_provider.name_identifier_format             = 'a' * 256
    @saml_provider.assertion_consumer_service_binding = 'a' * 256

    refute @saml_provider.valid?
    assert_error @saml_provider, :idp_homepage, :too_long, count: 255
    assert_error @saml_provider, :idp_entity_id, :too_long, count: 255
    assert_error @saml_provider, :idp_sso_target_url, :too_long, count: 255
    assert_error @saml_provider, :sp_entity_id, :too_long, count: 255
    assert_error @saml_provider, :assertion_consumer_service_url, :too_long, count: 255
    assert_error @saml_provider, :name_identifier_format, :too_long, count: 255
    assert_error @saml_provider, :assertion_consumer_service_binding, :too_long, count: 255
  end

  test 'invalid when default role for users is from different organization' do
    @saml_provider.default_role_for_users = roles :admin_twitter_role

    refute @saml_provider.valid?
    assert_error @saml_provider, :default_role_for_users, :invalid
  end
end
