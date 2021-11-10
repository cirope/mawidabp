require 'test_helper'

class ActivityTest < ActiveSupport::TestCase
  setup do
    @activity = activities :special_activity
  end

  test 'blank attributes' do
    @activity.name           = ''
    @activity.activity_group = nil

    assert @activity.invalid?
    assert_error @activity, :name, :blank
    assert_error @activity, :activity_group, :blank
  end

  test 'unique attributes' do
    activity = @activity.dup

    assert activity.invalid?
    assert_error activity, :name, :taken
  end

  test 'validates attributes length' do
    @activity.name = 'abcde' * 52

    assert @activity.invalid?
    assert_error @activity, :name, :too_long, count: 255
  end
end
