require 'test_helper'

class SettingTest < ActiveSupport::TestCase
  setup do
    @setting = settings :parameter_finding_stale_confirmed_days_default
  end

  test 'blank attributes' do
    @setting = Setting.new name: ''

    assert @setting.invalid?
    assert_error @setting, :name, :blank
    assert_error @setting, :value, :blank
    assert_error @setting, :organization, :blank
  end

  test 'validates attributes length' do
    @setting.name = @setting.value = 'abcde' * 52

    assert @setting.invalid?
    assert_error @setting, :name, :too_long, count: 255
    assert_error @setting, :value, :too_long, count: 255
  end

  test 'unique name scope organization' do
    @setting.name = settings(:parameter_allow_concurrent_sessions_default).name

    assert @setting.invalid?
    assert_error @setting, :name, :taken
  end

  test 'validates numericality attributes' do
    @setting.value = 'value'

    assert @setting.invalid?
    assert_error @setting, :value, :not_a_number
  end
end
