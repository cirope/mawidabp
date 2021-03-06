require 'test_helper'

class EMailsControllerTest < ActionController::TestCase
  setup do
    @email = e_mails :urgent_email

    login
  end

  test 'list e_mails' do
    get :index
    assert_response :success
    assert_not_nil assigns(:emails)
    assert_template 'e_mails/index'
  end

  test 'show email' do
    get :show, params: { id: @email.to_param }
    assert_response :success
    assert_not_nil assigns(:email)
    assert_template 'e_mails/show'
  end
end
