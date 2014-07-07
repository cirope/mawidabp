require 'test_helper'

class PollTest < ActiveSupport::TestCase
  def setup
    @poll = polls :poll_one

    set_organization
  end

  test 'create' do
    assert_difference ['Poll.count', 'Answer.count'] do
      Poll.list.create(
        :comments => 'New comments',
        :answered => false,
        :pollable_id => ActiveRecord::FixtureSet.identify(:conclusion_current_final_review),
        :pollable_type => 'ConclusionReview',
        :questionnaire_id => questionnaires(:questionnaire_one).id,
        :user_id => users(:poll_user).id,
        :answers_attributes => {
          '1' => {
            :answer => 'Answer'
          }
        }
       )
    end
  end

  test 'update' do
    assert_equal @poll.answered, false
    assert @poll.update(:comments => 'Updated comments'),
      @poll.errors.full_messages.join('; ')
    @poll.reload
    assert_equal 'Updated comments', @poll.comments
    assert_equal @poll.answered, true
  end

  test 'delete' do
    assert_difference 'Poll.count', -1 do
      assert_difference 'Answer.count', -2 do
        @poll.destroy
      end
    end
  end

  test 'validates blank attributes' do
    @poll = Poll.new

    assert @poll.invalid?
    assert_error @poll, :questionnaire, :blank
    assert_error @poll, :organization_id, :blank
    assert_error @poll, :base, :invalid

    @poll.customer_email = 'customer@email.com'
    @poll.user = users(:poll_user)

    assert @poll.invalid?
    assert_error @poll, :base, :invalid
    assert_equal 3, @poll.errors.count

    @poll.customer_email = 'customer@email.com'
    @poll.user = nil
    assert @poll.invalid?
    assert_equal 2, @poll.errors.count

    @poll.customer_email = nil
    @poll.user = users(:poll_user)
    assert @poll.invalid?
    assert_equal 2, @poll.errors.count
  end

  test 'validates length of attributes' do
    @poll.comments = 'abcde' * 52

    assert @poll.invalid?
    assert_error @poll, :comments, :too_long, count: 255
  end

  test 'validates pollable_type attribute' do
    assert_equal @poll.pollable_type, @poll.questionnaire.pollable_type
  end
end
