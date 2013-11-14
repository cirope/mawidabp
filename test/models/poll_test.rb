require 'test_helper'

class PollTest < ActiveSupport::TestCase
  def setup
    set_organization

    @poll = Poll.find polls(:poll_one).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Poll, @poll
    assert_equal polls(:poll_one).comments, @poll.comments
    assert_equal polls(:poll_one).questionnaire.id, @poll.questionnaire.id
    assert_equal polls(:poll_one).answered, @poll.answered
    assert_equal polls(:poll_one).user.id, @poll.user.id
    assert_equal polls(:poll_one).pollable.id, @poll.pollable.id
 end

  # Prueba la creación de una encuesta
  test 'create' do
    assert_difference ['Poll.count', 'Answer.count'] do
      Poll.create(
        :comments => 'New comments',
        :answered => false,
        :pollable_id => ActiveRecord::FixtureSet.identify(:conclusion_current_final_review),
        :pollable_type => 'ConclusionReview',
        :questionnaire_id => questionnaires(:questionnaire_one).id,
        :organization_id => organizations(:default_organization).id,
        :user_id => users(:poll_user).id,
        :answers_attributes => {
          '1' => {
            :answer => 'Answer'
          }
        }
       )
    end
  end

  # Prueba de actualización de una encuesta
  test 'update' do
    assert_equal @poll.answered, false
    assert @poll.update(:comments => 'Updated comments'),
      @poll.errors.full_messages.join('; ')
    @poll.reload
    assert_equal 'Updated comments', @poll.comments
    assert_equal @poll.answered, true
  end

  # Prueba de eliminación de una encuesta
  test 'delete' do
    assert_difference 'Poll.count', -1 do
      assert_difference 'Answer.count', -2 do
        @poll.destroy
      end
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @poll.user = nil
    @poll.questionnaire = nil
    @poll.organization = nil

    assert @poll.invalid?
    assert_error @poll, :questionnaire_id, :blank
    assert_error @poll, :organization_id, :blank
    assert_error @poll, :base, :invalid

    # Validación customer_email xor user
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

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @poll.comments = 'abcde' * 52

    assert @poll.invalid?
    assert_error @poll, :comments, :too_long, count: 255
  end

  test 'validates pollable_type attribute' do
    assert_equal @poll.pollable_type, @poll.questionnaire.pollable_type
  end
end
