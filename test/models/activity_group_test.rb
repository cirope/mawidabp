require 'test_helper'

class ActivityGroupTest < ActiveSupport::TestCase
  setup do
    @activity_group = activity_groups :special_activities
  end

  test 'blank attributes' do
    @activity_group.name = ''

    assert @activity_group.invalid?
    assert_error @activity_group, :name, :blank
  end

  test 'unique attributes' do
    activity_group = @activity_group.dup

    assert activity_group.invalid?
    assert_error activity_group, :name, :taken
  end

  test 'validates attributes length' do
    @activity_group.name = 'abcde' * 52

    assert @activity_group.invalid?
    assert_error @activity_group, :name, :too_long, count: 255
  end
end
