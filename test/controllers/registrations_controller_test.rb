require 'test_helper'

class RegistrationsControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper

  test 'new registration' do
    skip unless ENABLE_PUBLIC_REGISTRATION

    get :new
    assert_response :success
  end

  test 'create registration' do
    skip unless ENABLE_PUBLIC_REGISTRATION

    counts = %w[
      Group.count Organization.count License.count User.count
    ]

    assert_enqueued_emails 1 do
      assert_difference counts do
        post :create, params: {
          registration: {
            organization_name: 'public org',
            user:              'public_admin',
            name:              'Jane',
            last_name:         'Doe',
            email:             'admin@public.org'
          }
        }

        assert_redirected_to registration_url
      end
    end
  end

  test 'incomplete registration' do
    skip unless ENABLE_PUBLIC_REGISTRATION

    assert_enqueued_emails 0 do
      assert_no_difference ['Group.count', 'Organization.count', 'User.count'] do
        post :create, params: {
          registration: {
            organization_name: 'public org',
            email:             'admin@public.org',
            name:              'Jane'
          }
        }
      end
    end

    assert_response :success
    assert_template 'registrations/new'
  end

  test 'public registration disabled' do
    skip if ENABLE_PUBLIC_REGISTRATION

    get :new
    assert_redirected_to root_url
  end
end
