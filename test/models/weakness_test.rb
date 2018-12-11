require 'test_helper'

class WeaknessTest < ActiveSupport::TestCase
  setup do
    @weakness = findings :unanswered_weakness

    set_organization
  end

  test 'create' do
    assert_difference 'Weakness.count' do
      weakness = Weakness.list.create!(
        control_objective_item: control_objective_items(:impact_analysis_item_editable),
        title: 'Title',
        review_code: 'O020',
        description: 'New description',
        answer: 'New answer',
        audit_comments: 'New audit comments',
        state: Finding::STATUS[:notify],
        solution_date: nil,
        origination_date: 1.day.ago.to_date,
        audit_recommendations: 'New proposed action',
        effect: 'New effect',
        risk: Weakness.risks_values.first,
        priority: Weakness.priorities_values.first,
        follow_up_date: nil,
        compliance: 'no',
        operational_risk: ['internal fraud'],
        impact: ['econimic', 'regulatory'],
        internal_control_components: ['risk_evaluation', 'monitoring'],
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
        },
        taggings_attributes: {
          new_1: {
            tag_id: tags(:important).id
          },
          new_2: {
            tag_id: tags(:pending).id
          }
        }
      )

      assert_equal 'O020', weakness.review_code
    end
  end

  test 'control objective from final review can not be used to create new weakness' do
    assert_no_difference 'Weakness.count' do
      weakness = Weakness.list.create(
        control_objective_item: control_objective_items(:impact_analysis_item),
        title: 'Title',
        review_code: 'O020',
        description: 'New description',
        answer: 'New answer',
        audit_comments: 'New audit comments',
        state: Finding::STATUS[:notify],
        solution_date: nil,
        origination_date: 1.day.ago.to_date,
        audit_recommendations: 'New proposed action',
        effect: 'New effect',
        risk: Weakness.risks_values.first,
        priority: Weakness.priorities_values.first,
        follow_up_date: nil,
        compliance: 'no',
        operational_risk: ['internal fraud'],
        impact: ['econimic', 'regulatory'],
        internal_control_components: ['risk_evaluation', 'monitoring'],
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
        },
        taggings_attributes: {
          new_1: {
            tag_id: tags(:important).id
          },
          new_2: {
            tag_id: tags(:pending).id
          }
        }
      )

      assert_includes weakness.errors.full_messages, I18n.t('finding.readonly')
    end
  end

  test 'delete' do
    # On a final review, can not be destroyed
    assert_no_difference('Weakness.count') { @weakness.destroy }

    weakness = findings :unconfirmed_weakness

    # Without final review, also can not be destroyed =)
    assert_no_difference('Weakness.count') { weakness.destroy }
  end

  test 'validates blank attributes' do
    @weakness.state = Finding::STATUS[:notify] # To force audit recommendations check
    @weakness.control_objective_item_id = nil
    @weakness.review_code = '   '
    @weakness.audit_recommendations = '  '
    @weakness.risk = nil
    @weakness.priority = nil
    @weakness.compliance = ''
    @weakness.operational_risk = []
    @weakness.impact = []
    @weakness.internal_control_components = []
    @weakness.tag_ids = []

    if WEAKNESS_TAG_VALIDATION_START
      @weakness.created_at = WEAKNESS_TAG_VALIDATION_START
    end

    assert @weakness.invalid?
    assert_error @weakness, :control_objective_item_id, :blank
    assert_error @weakness, :review_code, :blank
    assert_error @weakness, :risk, :blank
    assert_error @weakness, :priority, :blank
    assert_error @weakness, :audit_recommendations, :blank

    if SHOW_WEAKNESS_EXTRA_ATTRIBUTES
      assert_error @weakness, :compliance, :blank
      assert_error @weakness, :operational_risk, :blank
      assert_error @weakness, :impact, :blank
      assert_error @weakness, :internal_control_components, :blank
    end

    if WEAKNESS_TAG_VALIDATION_START
      assert_error @weakness, :tag_ids, :blank
    end
  end

  test 'tag presence validation' do
    skip unless WEAKNESS_TAG_VALIDATION_START

    @weakness.created_at = WEAKNESS_TAG_VALIDATION_START - 1.second
    @weakness.tag_ids    = []

    assert @weakness.valid?

    @weakness.created_at = WEAKNESS_TAG_VALIDATION_START + 1.second

    assert @weakness.invalid?
    assert_error @weakness, :tag_ids, :blank
  end

  test 'validates duplicated attributes' do
    weakness = @weakness.dup

    assert weakness.invalid?
    assert_error weakness, :review_code, :taken

    # Not in the same review
    other = findings :unconfirmed_for_notification_weakness

    @weakness.review_code = other.review_code
    assert @weakness.valid?
  end

  test 'validates length of attributes' do
    @weakness.review_code = 'abcdd' * 52
    @weakness.title = 'abcdd' * 52

    assert @weakness.invalid?
    assert_error @weakness, :review_code, :too_long, count: 255
    assert_error @weakness, :title, :too_long, count: 255
  end

  test 'validates included attributes' do
    @weakness.state = Finding::STATUS.values.sort.last.next

    assert @weakness.invalid?
    assert_error @weakness, :state, :inclusion
  end

  test 'validates attributes boundaries' do
    @weakness.progress = -1

    assert @weakness.invalid?
    assert_error @weakness, :progress, :greater_than_or_equal_to, count: 0

    @weakness.progress = 101

    assert @weakness.invalid?
    assert_error @weakness, :progress, :less_than_or_equal_to, count: 100
  end

  test 'validates well formated attributes' do
    @weakness.review_code = 'BAD_PREFIX_2'

    assert @weakness.invalid?
    assert_error @weakness, :review_code, :invalid
  end

  test 'should allow revoked prefixed codes' do
    revoked_prefix = I18n.t 'code_prefixes.revoked'

    @weakness.review_code = "#{revoked_prefix}#{@weakness.review_code}"

    assert @weakness.valid?
  end

  test 'next code' do
    assert_equal 'O003', @weakness.next_code
  end

  test 'last work paper code' do
    assert_equal 'PTO 004', @weakness.last_work_paper_code
  end

  test 'progress is not updated when state change to awaiting' do
    skip unless SHOW_WEAKNESS_PROGRESS

    @weakness.update! state:          Finding::STATUS[:awaiting],
                      follow_up_date: Time.zone.today

    assert_equal 0, @weakness.progress
  end

  test 'progress is updated to 25 when state change to being implemented' do
    @weakness.update! state:          Finding::STATUS[:being_implemented],
                      follow_up_date: Time.zone.today

    assert_equal 25, @weakness.progress
  end

  test 'progress is updated to 100 when state change to implemented' do
    @weakness.update! state:          Finding::STATUS[:implemented],
                      follow_up_date: Time.zone.today

    assert_equal 100, @weakness.progress
  end

  test 'default progress for' do
    assert_equal 100, Weakness.default_progress_for(state: Finding::STATUS[:implemented])
    assert_equal 0,   Weakness.default_progress_for(state: Finding::STATUS[:awaiting])
    assert_equal 25,  Weakness.default_progress_for(state: Finding::STATUS[:being_implemented])
  end

  test 'review code is updated when control objective is changed' do
    weakness                   = findings :being_implemented_weakness_on_draft
    new_control_objective_item = control_objective_items :organization_security_4_2_item_editable

    assert_not_equal 'O006', weakness.review_code

    weakness.update! control_objective_item_id: new_control_objective_item.id

    assert_equal 'O006', weakness.review_code
  end

  test 'can not change to a control objective in a final review' do
    weakness = findings :being_implemented_weakness_on_draft

    assert_raise RuntimeError do
      weakness.update(
        control_objective_item_id:
          control_objective_items(:security_policy_3_1_item).id
      )
    end
  end

  test 'work paper codes are updated when control objective is changed' do
    weakness = findings :unanswered_for_level_1_notification

    assert_not_equal 'PTO 006', weakness.work_papers.first.code

    weakness.update!(
      control_objective_item_id:
        control_objective_items(:impact_analysis_item_editable).id
    )

    assert_equal 'PTO 006', weakness.work_papers.first.code
  end

  test 'dynamic status functions' do
    Finding::STATUS.each do |status, value|
      @weakness.state = value
      assert @weakness.send(:"#{status}?")

      Finding::STATUS.each do |k, v|
        unless k == status
          @weakness.state = v

          refute @weakness.send(:"#{status}?")
        end
      end
    end
  end

  test 'risk text' do
    risk = Weakness.risks.detect { |r| r.last == @weakness.risk }

    assert_equal I18n.t("risk_types.#{risk.first}"), @weakness.risk_text
  end

  test 'priority text' do
    priority = Weakness.priorities.detect { |p| p.last == @weakness.priority }

    assert_equal I18n.t("priority_types.#{priority.first}"), @weakness.priority_text
  end

  test 'must be approved on implemented audited' do
    error_messages = [I18n.t('weakness.errors.without_solution_date')]

    @weakness.state = Finding::STATUS[:implemented_audited]
    @weakness.solution_date = nil

    refute @weakness.must_be_approved?
    assert_equal error_messages.sort, @weakness.approval_errors.sort
  end

  test 'must be approved on implemented' do
    error_messages = [
      I18n.t('weakness.errors.with_solution_date'),
      I18n.t('weakness.errors.without_follow_up_date')
    ]

    @weakness.state = Finding::STATUS[:implemented]
    @weakness.solution_date = 2.days.from_now.to_date
    @weakness.follow_up_date = nil

    refute @weakness.must_be_approved?
    assert_equal error_messages.sort, @weakness.approval_errors.sort
  end

  test 'must be approved on being implemented' do
    error_messages = [
      I18n.t('weakness.errors.without_answer'),
      I18n.t('weakness.errors.without_follow_up_date')
    ]

    @weakness.state = Finding::STATUS[:being_implemented]
    @weakness.answer = ' '

    refute @weakness.must_be_approved?
    assert_equal error_messages.sort, @weakness.approval_errors.sort
  end

  test 'must be approved invalid state' do
    error_messages = [I18n.t('weakness.errors.not_valid_state')]

    @weakness.state = Finding::STATUS[:notify]

    refute @weakness.must_be_approved?
    assert_equal error_messages.sort, @weakness.approval_errors.sort
  end

  test 'must be approved on users' do
    error_messages = [I18n.t('weakness.errors.without_audited')]

    @weakness.finding_user_assignments =
      @weakness.finding_user_assignments.reject do |fua|
        fua.user.can_act_as_audited?
      end

    refute @weakness.must_be_approved?
    assert_equal error_messages.sort, @weakness.approval_errors.sort

    error_messages << I18n.t('weakness.errors.without_auditor')

    @weakness.finding_user_assignments =
      @weakness.reload.finding_user_assignments.reject do |fua|
        fua.user.auditor?
      end

    refute @weakness.must_be_approved?
    assert_equal error_messages.sort, @weakness.approval_errors.sort
  end

  test 'must be approved on required attributes' do
    error_messages = if HIDE_WEAKNESS_EFFECT
                       [I18n.t('weakness.errors.without_audit_comments')]
                     else
                       [
                         I18n.t('weakness.errors.without_effect'),
                         I18n.t('weakness.errors.without_audit_comments')
                       ]
                     end

    @weakness.effect = ' '
    @weakness.audit_comments = '  '

    if SHOW_CONCLUSION_ALTERNATIVE_PDF && HIDE_WEAKNESS_EFFECT
      assert @weakness.must_be_approved?
    else
      refute @weakness.must_be_approved?
      assert_equal error_messages.sort, @weakness.approval_errors.sort
    end
  end

  test 'must be approved on tasks' do
    error_messages = [I18n.t('weakness.errors.with_expired_tasks')]

    @weakness.tasks.build(description: 'Test task', due_on: Time.zone.yesterday)

    refute @weakness.must_be_approved?
    assert_equal error_messages.sort, @weakness.approval_errors.sort
  end

  test 'work papers can be added to weakness with current close date' do
    uneditable_weakness = findings :being_implemented_weakness

    assert_difference 'WorkPaper.count' do
      uneditable_weakness.update(
        work_papers_attributes: {
          '1_new' => {
            name: 'New post_workpaper name',
            code: 'PTO 020',
            file_model_attributes: {
              file: Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH, 'text/plain')
            }
          }
        }
      )
    end
  end

  test 'work papers can not be added to weakness with expired close date' do
    uneditable_weakness       = findings :being_implemented_weakness_on_final
    uneditable_weakness.final = true

    assert_no_difference 'WorkPaper.count' do
      assert_raise RuntimeError do
        uneditable_weakness.update(
        work_papers_attributes: {
            '1_new' => {
              name: 'New post_workpaper name',
              code: 'PTO 020',
              file_model_attributes: {
                file: Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH, 'text/plain')
              }
            }
          }
        )
      end
    end
  end

  test 'list all follow up dates and rescheduled function' do
    weakness = findings :being_implemented_weakness_on_approved_draft
    old_date = weakness.follow_up_date.clone

    create_conclusion_final_review_for weakness

    assert weakness.reload.all_follow_up_dates.blank?
    refute weakness.rescheduled?
    assert_not_nil weakness.follow_up_date

    weakness.update! follow_up_date: 10.days.from_now.to_date

    assert weakness.all_follow_up_dates(nil, true).include?(old_date)
    assert weakness.rescheduled?

    weakness.update! follow_up_date: 15.days.from_now.to_date

    assert weakness.all_follow_up_dates(nil, true).include?(old_date)
    assert weakness.all_follow_up_dates(nil, true).include?(10.days.from_now.to_date)
  end

  test 'do not reschedule or show previous dates if no conclusion final review' do
    weakness = findings :being_implemented_weakness_on_approved_draft
    old_date = weakness.follow_up_date.clone

    assert weakness.all_follow_up_dates.blank?
    refute weakness.rescheduled?
    assert_not_nil weakness.follow_up_date

    weakness.update! follow_up_date: 10.days.from_now.to_date

    assert weakness.all_follow_up_dates.blank?
    refute weakness.rescheduled?
  end

  private

    def create_conclusion_final_review_for weakness
      ConclusionFinalReview.list.create!(
        review:                  weakness.review,
        issue_date:              Time.zone.today,
        close_date:              2.days.from_now.to_date,
        applied_procedures:      'New applied procedures',
        conclusion:              CONCLUSION_OPTIONS.first,
        recipients:              'John Doe',
        sectors:                 'Area 51',
        evolution:               EVOLUTION_OPTIONS.second,
        evolution_justification: 'Ok',
        main_weaknesses_text:    'Some main weakness X',
        corrective_actions:      'You should do it this way',
        affects_compliance:      false
      )
    end
end
