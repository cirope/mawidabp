require 'test_helper'

class FindingAnswerTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @finding_answer = finding_answers :auditor_answer
  end

  test 'auditor create without notification' do
    assert_no_enqueued_emails do
      assert_difference ['FindingAnswer.count', 'Reading.count'] do
        @finding_answer = FindingAnswer.create(
          answer: 'New answer',
          finding: findings(:unanswered_weakness),
          user: users(:supervisor),
          file_model: file_models(:text_file),
          notify_users: false
        )
      end
    end
  end

  test 'audited create without notification' do
    assert_no_enqueued_emails do
      assert_difference 'FindingAnswer.count' do
        @finding_answer = FindingAnswer.create(
          answer: 'New answer',
          commitment_date: 10.days.from_now.to_date,
          finding: findings(:unanswered_weakness),
          user: users(:audited),
          file_model: file_models(:text_file),
          notify_users: false
        )
      end
    end
  end

  test 'auditor create with notification' do
    assert_enqueued_emails 1 do
      assert_difference 'FindingAnswer.count' do
        @finding_answer = FindingAnswer.create(
          answer: 'New answer',
          finding: findings(:unanswered_weakness),
          user: users(:supervisor),
          file_model: file_models(:text_file),
          notify_users: true
        )
      end
    end
  end

  test 'audited create with notification' do
    assert_enqueued_emails 1 do
      assert_difference 'FindingAnswer.count' do
        @finding_answer = FindingAnswer.create(
          answer: 'New answer',
          commitment_date: 10.days.from_now.to_date,
          finding: findings(:unanswered_weakness),
          user: users(:audited),
          file_model: file_models(:text_file)
          # notify_users nil which converts to true
        )
      end
    end
  end

  test 'update' do
    assert @finding_answer.update(answer: 'New answer')

    assert_not_equal 'New answer', @finding_answer.reload.answer
  end

  test 'delete' do
    assert_difference 'FindingAnswer.count', -1 do
      @finding_answer.destroy
    end
  end

  test 'validates blank attributes with auditor' do
    @finding_answer.answer = '      '
    @finding_answer.finding_id = nil
    @finding_answer.commitment_date = ''

    assert @finding_answer.invalid?
    assert_error @finding_answer, :answer, :blank
    assert_error @finding_answer, :finding_id, :blank
  end

  test 'validates blank attributes with audited' do
    Current.organization_id = organizations(:cirope).id

    @finding_answer.user = users(:audited)
    @finding_answer.answer = ' '
    @finding_answer.finding = findings(:being_implemented_weakness_on_final)
    @finding_answer.commitment_date = nil

    assert @finding_answer.invalid?
    assert_error @finding_answer, :answer, :blank
    assert_error @finding_answer, :commitment_date, :blank

    Current.organization_id = nil
  end

  test 'validates well formated attributes' do
    @finding_answer.commitment_date = '13/13/13'

    assert @finding_answer.invalid?
    assert_error @finding_answer, :commitment_date, :invalid_date
  end

  test 'requires commitment date' do
    Current.organization_id = organizations(:cirope).id

    @finding_answer.user = users(:audited)
    @finding_answer.finding = findings(:being_implemented_weakness_on_final)
    @finding_answer.commitment_date = nil

    assert @finding_answer.requires_commitment_date?

    @finding_answer.finding.follow_up_date = Time.zone.today

    assert !@finding_answer.requires_commitment_date?

    @finding_answer.finding.follow_up_date = 1.day.ago

    assert @finding_answer.requires_commitment_date?

    Current.organization_id = nil
  end
end
