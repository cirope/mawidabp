require 'test_helper'

class OrganizationsHelperTest < ActionView::TestCase
  include FontAwesome::Sass::Rails::ViewHelpers

  test 'should return blank link to remove authentication configuration' do
    new_saml_provider = SamlProvider.new
    template          = Object.new

    template.extend ActionView::Helpers::FormHelper
    template.extend ActionView::Helpers::FormOptionsHelper

    form_builder = SimpleForm::FormBuilder.new :saml_provider, new_saml_provider, template, {}

    assert link_to_remove_authentication_configuration(form_builder).blank?
  end

  test 'should return link to remove authentication configuration' do
    new_saml_provider = SamlProvider.new provider: 'azure',
                                         idp_homepage: 'https://login.microsoftonline.com/test/federationmetadata/2007-06/federationmetadata.xml',
                                         idp_entity_id: 'https://sts.windows.net/test/',
                                         idp_sso_target_url: 'https://login.microsoftonline.com/test/saml2',
                                         sp_entity_id: 'https://test.com/saml/metadata',
                                         assertion_consumer_service_url: 'https://test.com/saml/callback',
                                         name_identifier_format: 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
                                         assertion_consumer_service_binding: 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
                                         idp_cert: 'cert_test',
                                         username_claim: 'name',
                                         name_claim: 'givenname',
                                         lastname_claim: 'surname',
                                         email_claim: 'name',
                                         roles_claim: 'groups',
                                         organization: organizations(:cirope)

    new_saml_provider.save!

    template = Object.new

    template.extend ActionView::Helpers::FormHelper
    template.extend ActionView::Helpers::FormOptionsHelper

    form_builder = SimpleForm::FormBuilder.new :saml_provider, new_saml_provider, template, {}
    link_to      = link_to_remove_authentication_configuration form_builder
    expected     = ''

    expected << form_builder.hidden_field(
      :_destroy,
      class: 'destroy',
      value: 0,
      id: "remove_#{new_saml_provider.class.name.underscore}_hidden_#{new_saml_provider.object_id}"
    )

    expected << link_to(
      icon('fas', 'times-circle'), '#',
      title: t('label.delete'),
      class: 'float-end',
      data: {
        'dynamic-target' => "##{new_saml_provider.class.name.underscore}",
        'dynamic-form-event' => 'hideCard',
        'show-tooltip' => true
      }
    )

    assert_equal link_to, expected
  end
end
