require 'test_helper'

class RegistrationTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    skip unless ENABLE_PUBLIC_REGISTRATION

    @registration = Registration.new(
      organization_name: 'public org',
      user:              'public_admin',
      name:              'Jane',
      last_name:         'Doe',
      email:             'admin@public.org'
    )
  end

  test 'create' do
    emails_count = NOTIFY_NEW_ADMIN ? 2 : 1
    counts       = %w[
      Group.count Organization.count License.count User.count
    ]

    assert_difference counts do
      assert_enqueued_emails emails_count do
        assert @registration.save
      end
    end
  end

  test 'validates blank attributes' do
    @registration.organization_name = nil
    @registration.name              = nil
    @registration.last_name         = nil
    @registration.email             = '  '

    assert @registration.invalid?
    assert_error @registration, :organization_name, :blank
    assert_error @registration, :name, :blank
    assert_error @registration, :last_name, :blank
    assert_error @registration, :email, :blank
  end

  test 'validates well formated attributes' do
    @registration.email = 'incorrect@format'

    assert @registration.invalid?
    assert_error @registration, :email, :invalid
  end

  test 'validates duplicated attributes' do
    @registration.email             = groups(:main_group).admin_email
    @registration.organization_name = groups(:main_group).name

    assert @registration.invalid?
    assert_error @registration, :email, :taken
    assert_error @registration, :organization_name, :taken

    @registration.organization_name = organizations(:cirope).name

    assert @registration.invalid?
    assert_error @registration, :organization_name, :taken

    @registration.organization_name = organizations(:cirope).prefix

    assert @registration.invalid?
    assert_error @registration, :organization_name, :taken
  end

  test 'validates length of attributes' do
    @registration.user = 'ab'

    assert @registration.invalid?
    assert_error @registration, :user, :too_short, count: 3

    @registration.user      = 'abcde' * 52
    @registration.name      = 'abcde' * 21
    @registration.last_name = 'abcde' * 21
    @registration.email     = "#{'abcde' * 52}@email.com"

    assert @registration.invalid?
    assert_error @registration, :user, :too_long, count: 255
    assert_error @registration, :name, :too_long, count: 100
    assert_error @registration, :last_name, :too_long, count: 100
    assert_error @registration, :email, :too_long, count: 255
  end
end
