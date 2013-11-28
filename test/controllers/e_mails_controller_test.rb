require 'test_helper'

class EMailsControllerTest < ActionController::TestCase
  fixtures :e_mails

  setup do
    @email = e_mails(:urgent_email)

    perform_auth
  end

  test 'list e_mails' do
    get :index
    assert_response :success
    assert_not_nil assigns(:emails)
    assert_select '#error_body', false
    assert_template 'e_mails/index'
  end

  test 'show email' do
    get :show, :id => @email.to_param
    assert_response :success
    assert_not_nil assigns(:email)
    assert_select '#error_body', false
    assert_template 'e_mails/show'
  end
end
