require 'test_helper'

class RegistrationsControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper

  test 'new registration' do
    get :new
    assert_response :success
  end

  test 'create registration' do
    assert_enqueued_emails 1 do
      assert_difference ['Group.count', 'Organization.count', 'User.count'] do
        post :create, params: {
          registration: {
            organization: 'public org',
            user:         'public_admin',
            name:         'Jane',
            last_name:    'Doe',
            email:        'admin@public.org',
            language:     'es'
          }
        }
      end
    end
  end
end
