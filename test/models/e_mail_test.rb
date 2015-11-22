require 'test_helper'

class EMailTest < ActiveSupport::TestCase
  def setup
    @email = e_mails :urgent_email
  end

  test 'create' do
    assert_difference 'EMail.count' do
      @email = EMail.create(
        to: 'someone@mawida.com',
        subject: 'Some thing',
        body: 'Some text'
      )
    end
  end

  test 'update' do
    assert @email.update(to: 'other@mawida.com'),
      @email.errors.full_messages.join('; ')

    assert_equal 'other@mawida.com', @email.reload.to
  end

  test 'delete' do
    assert_difference('EMail.count', -1) { @email.destroy }
  end

  test 'validates blank attributes' do
    @email = EMail.new to: ''

    assert @email.invalid?
    assert_error @email, :to, :blank
    assert_error @email, :subject, :blank
  end
end
