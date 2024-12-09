require 'test_helper'

class PollTest < ActiveSupport::TestCase
  setup do
    @poll = polls :poll_one

    set_organization
  end

  test 'initialize and build questions' do
    poll = Poll.list.new(
      :comments => 'New comments',
      :answered => false,
      :pollable_id => ActiveRecord::FixtureSet.identify(:conclusion_current_final_review),
      :pollable_type => 'ConclusionReview',
      :questionnaire_id => questionnaires(:questionnaire_one).id,
      :user_id => users(:poll).id
    )

    poll.answers.each do |answer|
      assert answer.question.present?

      if answer.question.answer_yes_no?
        assert_equal answer.type, AnswerYesNo.name
      elsif answer.question.answer_multi_choice?
        assert_equal answer.type, AnswerMultiChoice.name
      elsif answer.question.answer_written?
        assert_equal answer.type, AnswerWritten.name
      end
    end
  end

  test 'create' do
    assert_difference ['Poll.count', 'Answer.count'] do
      Poll.list.create(
        :comments => 'New comments',
        :answered => false,
        :pollable_id => ActiveRecord::FixtureSet.identify(:conclusion_current_final_review),
        :pollable_type => 'ConclusionReview',
        :questionnaire_id => questionnaires(:questionnaire_one).id,
        :user_id => users(:poll).id,
        :answers_attributes => {
          '1' => {
            :answer => 'Answer'
          }
        }
       )
    end
  end

  test 'update and finished when temporary polls setting is false and not complete all answers' do
    assert_equal @poll.answered, false
    assert @poll.update(comments: 'Updated comments'),
           @poll.errors.full_messages.join('; ')

    @poll.reload

    assert_equal 'Updated comments', @poll.comments
    assert_equal @poll.answered, true
  end

  test 'update and finished when temporary polls setting is false and complete all answers' do
    assert_equal @poll.answered, false

    answer_yes_no = @poll.answers.find_by type: 'AnswerYesNo'

    @poll.update comments: 'Updated comments',
                 answers_attributes:
                 [
                   {
                     id: answer_yes_no.id,
                     answer_option_id: answer_options(:yes_no_no).id
                   }
                 ]

    @poll.reload

    assert_equal 'Updated comments', @poll.comments
    assert_equal @poll.answered, true
  end

  test 'update and not finished yet when temporary polls setting is true and not complete all answers' do
    set_temporary_polls @poll

    assert_equal @poll.answered, false
    assert @poll.update(comments: 'Updated comments'),
           @poll.errors.full_messages.join('; ')

    @poll.reload

    assert_equal 'Updated comments', @poll.comments
    assert_equal @poll.answered, false
  end

  test 'update and finished when temporary polls setting is true and complete all answers' do
    set_temporary_polls @poll

    assert_equal @poll.answered, false

    answer_yes_no = @poll.answers.find_by type: 'AnswerYesNo'

    @poll.update comments: 'Updated comments',
                 answers_attributes:
                 [
                   {
                     id: answer_yes_no.id,
                     answer_option_id: answer_options(:yes_no_no).id
                   }
                 ]

    @poll.reload

    assert_equal 'Updated comments', @poll.comments
    assert_equal @poll.answered, true
  end

  test 'delete' do
    assert_difference 'Poll.count', -1 do
      assert_difference 'Answer.count', -@poll.answers.count do
        @poll.destroy
      end
    end
  end

  test 'validates blank attributes' do
    @poll = Poll.new

    assert @poll.invalid?
    assert_error @poll, :questionnaire, :blank
    assert_error @poll, :user, :blank
    assert_error @poll, :organization_id, :blank
  end

  test 'validates pollable_type attribute' do
    assert_equal @poll.pollable_type, @poll.questionnaire.pollable_type
  end

  test 'validates about type attribute' do
    @poll.about_id   = nil
    @poll.about_type = nil

    assert @poll.valid?

    @poll.about_id = users(:auditor).id

    assert @poll.invalid?
    assert_error @poll, :about_type, :blank

    @poll.about_type = 'OtherClass'

    assert @poll.invalid?
    assert_error @poll, :about_type, :inclusion

    @poll.about_type = User.name
    assert @poll.valid?
  end

  private

    def set_temporary_polls poll
      poll.organization.settings.find_by(name: 'temporary_polls').update value: '1'
    end
end
