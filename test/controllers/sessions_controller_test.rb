require 'test_helper'
require 'minitest/mock'

class SessionsControllerTest < ActionController::TestCase
  setup do
    @organization = organizations(:cirope)
    @user = users :administrator

    set_host_for_organization(@organization.prefix)
  end

  test 'should get login' do
    get :new
    assert_response :success
    assert_template 'sessions/new'
  end

  test 'should redirect to login azure' do
    @external_saml_url = 'https://login.saml/saml2'
    create_saml_provider @organization

    set_host_for_organization @organization.prefix

    response_stub =
      OneLogin::RubySaml::Settings.new({ idp_sso_target_url: @external_saml_url })

    IdpSettingsAdapter.stub :saml_settings, response_stub do
      mock = Minitest::Mock.new

      mock.expect :create, @external_saml_url, [response_stub]
      mock.expect :request_id, '91dfe9376a2e8e09e6dcb444c04fc53a'

      OneLogin::RubySaml::Authrequest.stub :new, mock do
        post :create, params: { user: @user.user }

        assert_redirected_to @external_saml_url
      end
    end
  end

  test 'should ask for password' do
    post :create, params: { user: @user.user }

    assert_redirected_to signin_url
  end

  test 'should create a new session' do
    post :create, params: { user: @user.user }

    @controller = AuthenticationsController.new

    post :create, params: { password: 'admin123' }

    assert_redirected_to welcome_url
    assert_equal @user.id, @controller.current_user
  end

  test 'login without organization' do
    @request.host = URL_HOST

    post :create, params: { user: @user.user }

    assert_redirected_to login_url
    assert_equal I18n.t('message.no_organization'), flash.alert
  end

  test 'redirected instead of relogin' do
    login

    get :new
    assert_redirected_to welcome_url
  end

  test 'logout' do
    login

    delete :destroy
    assert_nil session[:user_id]
    assert_redirected_to login_url
  end

  private

    def error_record error_type
      ErrorRecord.where(user: @user, error: ErrorRecord::ERRORS[error_type]).
        order('created_at DESC').first
    end

    def create_saml_provider organization
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
                                           organization: organization

      new_saml_provider.save!
    end
end
