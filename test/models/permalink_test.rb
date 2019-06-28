require 'test_helper'

class PermalinkTest < ActiveSupport::TestCase
  setup do
    @permalink = permalinks :link
  end

  test 'blank attributes' do
    @permalink.token = ''
    @permalink.action = ''

    assert @permalink.invalid?
    assert_error @permalink, :token, :blank
    assert_error @permalink, :action, :blank
  end

  test 'unique attributes' do
    permalink = @permalink.dup

    assert permalink.invalid?
    assert_error permalink, :token, :taken
  end

  test 'as options' do
    options = @permalink.as_options

    assert_equal 'follow_up_audit', options[:controller]
    assert_equal 'weaknesses_current_situation', options[:action]
    assert_equal @permalink.token, options[:permalink_token]
  end
end
