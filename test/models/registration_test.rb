require 'test_helper'

class RegistrationTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @registration = Registration.new(
      organization: 'public org',
      user:         'public_admin',
      name:         'Jane',
      last_name:    'Doe',
      email:        'admin@public.org',
      language:     'es'
    )
  end

  test 'create' do
    assert_difference ['Group.count', 'Organization.count', 'User.count'] do
      assert_enqueued_emails 1 do
        assert @registration.save
      end
    end
  end

  test 'validates blank attributes' do
    @registration.name = nil
    @registration.last_name = nil
    @registration.language = '   '
    @registration.email = '  '

    assert @registration.invalid?
    assert_error @registration, :name, :blank
    assert_error @registration, :last_name, :blank
    assert_error @registration, :language, :blank
    assert_error @registration, :email, :blank
  end

  test 'validates well formated attributes' do
    @registration.email = 'incorrect@format'

    assert @registration.invalid?
    assert_error @registration, :email, :invalid
  end

  test 'validates duplicated attributes' do
    @registration.email = groups(:main_group).admin_email

    assert @registration.invalid?
    assert_error @registration, :email, :taken
  end

  test 'validates length of attributes' do
    @registration.user = 'ab'

    assert @registration.invalid?
    assert_error @registration, :user, :too_short, count: 3

    @registration.user = 'abcd' * 10
    @registration.name = 'abcde' * 21
    @registration.last_name = 'abcde' * 21
    @registration.email = "#{'abcde' * 21}@email.com"

    assert @registration.invalid?
    assert_error @registration, :user, :too_long, count: 30
    assert_error @registration, :name, :too_long, count: 100
    assert_error @registration, :last_name, :too_long, count: 100
    assert_error @registration, :email, :too_long, count: 100
  end
end
