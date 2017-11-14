require 'test_helper'

class OportunityTest < ActiveSupport::TestCase
  setup do
    @oportunity = findings :confirmed_oportunity

    set_organization
  end

  test 'create' do
    assert_difference 'Oportunity.count' do
      @oportunity = Oportunity.list.create!(
        control_objective_item: control_objective_items(:impact_analysis_item_editable),
        review_code: 'OM20',
        title: 'Title',
        description: 'New description',
        answer: 'New answer',
        audit_comments: 'New audit comments',
        state: Finding::STATUS[:being_implemented],
        finding_user_assignments_attributes: {
          new_1: {
            user_id: users(:audited).id, process_owner: false
          },
          new_2: {
            user_id: users(:auditor).id, process_owner: false
          },
          new_3: {
            user_id: users(:supervisor).id, process_owner: false
          }
        }
      )

      assert_equal 'OM20', @oportunity.review_code
    end
  end

  test 'control objective from final review can not be used to create new oportunity' do
    assert_no_difference 'Oportunity.count' do
      oportunity = Oportunity.list.create(
        control_objective_item: control_objective_items(:impact_analysis_item),
        review_code: 'OM20',
        title: 'Title',
        description: 'New description',
        answer: 'New answer',
        audit_comments: 'New audit comments',
        state: Finding::STATUS[:being_implemented],
        finding_user_assignments_attributes: {
          new_1: {
            user_id: users(:audited).id, process_owner: false
          },
          new_2: {
            user_id: users(:auditor).id, process_owner: false
          },
          new_3: {
            user_id: users(:supervisor).id, process_owner: false
          }
        }
      )

      assert_includes oportunity.errors.full_messages, I18n.t('finding.readonly')
    end
  end

  test 'delete' do
    # On a final review, can not be destroyed
    assert_no_difference('Oportunity.count') { @oportunity.destroy }

    oportunity = findings :unconfirmed_oportunity

    # Without final review, also can not be destroyed =)
    assert_no_difference('Oportunity.count') { oportunity.destroy }
  end

  test 'validates blank attributes' do
    @oportunity.control_objective_item_id = nil
    @oportunity.review_code = '   '

    assert @oportunity.invalid?
    assert_error @oportunity, :control_objective_item_id, :blank
    assert_error @oportunity, :review_code, :blank
  end

  test 'validates duplicated attributes' do
    oportunity = @oportunity.dup

    assert oportunity.invalid?
    assert_error oportunity, :review_code, :taken
  end

  test 'validates length of attributes' do
    @oportunity.review_code = 'abcdd' * 52
    @oportunity.title = 'abcdd' * 52

    assert @oportunity.invalid?
    assert_error @oportunity, :review_code, :too_long, count: 255
    assert_error @oportunity, :title, :too_long, count: 255
  end

  test 'validates included attributes' do
    @oportunity.state = Finding::STATUS.values.sort.last.next

    assert @oportunity.invalid?
    assert_error @oportunity, :state, :inclusion
  end

  test 'validates well formated attributes' do
    @oportunity.review_code = 'BAD_PREFIX_2'

    assert @oportunity.invalid?
    assert_error @oportunity, :review_code, :invalid
  end

  test 'next code' do
    assert_equal 'OM003', @oportunity.next_code
  end

  test 'next work paper code' do
    assert_equal 'PTOM 000', @oportunity.last_work_paper_code
  end

  test 'review code is updated when control objective is changed' do
    oportunity = findings :confirmed_oportunity_on_draft

    assert_not_equal 'OM004', oportunity.review_code

    oportunity.update!(
      control_objective_item_id:
        control_objective_items(:impact_analysis_item_editable).id
    )

    assert_equal 'OM004', oportunity.review_code
  end

  test 'can not change to a control objective in a final review' do
    oportunity = findings :confirmed_oportunity_on_draft

    assert_raise RuntimeError do
      oportunity.update(control_objective_item_id:
        control_objective_items(:security_policy_3_1_item).id)
    end
  end

  test 'work paper codes are updated when control objective is changed' do
    oportunity = findings :confirmed_oportunity_on_draft

    assert_not_equal 'PTOM 004', oportunity.work_papers.first.code

    oportunity.update!(
      control_objective_item_id:
        control_objective_items(:impact_analysis_item_editable).id
    )

    assert_equal 'PTOM 004', oportunity.work_papers.first.code
  end

  test 'must be approved on implemented audited' do
    error_messages = [I18n.t('oportunity.errors.without_solution_date')]

    @oportunity.state = Finding::STATUS[:implemented_audited]
    @oportunity.solution_date = nil

    refute @oportunity.must_be_approved?
    assert_equal error_messages.sort, @oportunity.approval_errors.sort
  end

  test 'must be approved on implemented' do
    error_messages = [
      I18n.t('oportunity.errors.with_solution_date'),
      I18n.t('oportunity.errors.without_follow_up_date')
    ]

    @oportunity.state = Finding::STATUS[:implemented]
    @oportunity.solution_date = 2.days.from_now.to_date
    @oportunity.follow_up_date = nil

    refute @oportunity.must_be_approved?
    assert_equal error_messages.sort, @oportunity.approval_errors.sort
  end

  test 'must be approved on being implemented' do
    error_messages = [
      I18n.t('oportunity.errors.without_answer'),
      I18n.t('oportunity.errors.without_follow_up_date')
    ]

    @oportunity.state = Finding::STATUS[:being_implemented]
    @oportunity.answer = ' '

    refute @oportunity.must_be_approved?
    assert_equal error_messages.sort, @oportunity.approval_errors.sort
  end

  test 'must be approved invalid state' do
    error_messages = [I18n.t('oportunity.errors.not_valid_state')]

    @oportunity.state = Finding::STATUS[:notify]

    refute @oportunity.must_be_approved?
    assert_equal error_messages.sort, @oportunity.approval_errors.sort
  end

  test 'must be approved on users' do
    error_messages = [I18n.t('oportunity.errors.without_audited')]

    @oportunity.state = Finding::STATUS[:assumed_risk]
    @oportunity.finding_user_assignments =
      @oportunity.finding_user_assignments.reject do |fua|
        fua.user.can_act_as_audited?
      end

    refute @oportunity.must_be_approved?
    assert_equal error_messages.sort, @oportunity.approval_errors.sort

    error_messages << I18n.t('oportunity.errors.without_auditor')

    @oportunity.finding_user_assignments =
      @oportunity.finding_user_assignments.reject { |fua| fua.user.auditor? }
    refute @oportunity.must_be_approved?
    assert_equal error_messages.sort, @oportunity.approval_errors.sort
  end

  test 'must be approved on required attributes' do
    error_messages = [I18n.t('oportunity.errors.without_audit_comments')]

    @oportunity.state = Finding::STATUS[:assumed_risk]
    @oportunity.audit_comments = '  '

    if SHOW_CONCLUSION_ALTERNATIVE_PDF
      assert @oportunity.must_be_approved?
    else
      refute @oportunity.must_be_approved?
      assert_equal error_messages.sort, @oportunity.approval_errors.sort
    end

  end

  test 'dynamic status functions' do
    Finding::STATUS.each do |status, value|
      @oportunity.state = value
      assert @oportunity.send(:"#{status}?")

      Finding::STATUS.each do |k, v|
        unless k == status
          @oportunity.state = v

          refute @oportunity.send(:"#{status}?")
        end
      end
    end
  end
end
