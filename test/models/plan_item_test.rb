require 'test_helper'

class PlanItemTest < ActiveSupport::TestCase
  setup do
    @plan_item   = plan_items :current_plan_item_1
    Current.user = users :supervisor

    set_organization
  end

  teardown do
    Current.user = nil
  end

  test 'create' do
    assert_difference 'PlanItem.count' do
      plan = plans :current_plan

      plan.plan_items.create!(
        project: 'New project',
        start: 6.days.from_now.to_date,
        end: 7.days.from_now.to_date,
        order_number: 4,
        scope: 'committee',
        risk_exposure: 'high',
        plan: plan,
        business_unit: business_units(:business_unit_one)
      )
    end
  end

  test 'update' do
    assert @plan_item.update(project: 'Updated project'), @plan_item.errors.full_messages.join('; ')

    @plan_item.reload

    assert_equal 'Updated project', @plan_item.project
  end

  test 'destroy' do
    plan_item = plan_items :past_plan_item_3

    assert_difference 'PlanItem.count', -1 do
      plan_item.destroy
    end
  end

  test 'delete' do
    assert_no_difference 'PlanItem.count' do
      @plan_item.destroy
    end

    assert_equal 'Plan item is already related and can not be destroyed',
      @plan_item.errors[:base].join
  end

  test 'validates formated attributes' do
    @plan_item.order_number = '_1'
    @plan_item.start = '_1'
    @plan_item.end = '_1'

    assert @plan_item.invalid?
    assert_error @plan_item, :order_number, :not_a_number
    assert_error @plan_item, :start, :invalid_date
    assert_error @plan_item, :end, :invalid_date
  end

  test 'validates blank attributes' do
    @plan_item.project = nil
    @plan_item.order_number = nil
    @plan_item.start = nil
    @plan_item.end = '   '
    @plan_item.scope = '   '
    @plan_item.risk_exposure = '   '

    assert @plan_item.invalid?
    assert_error @plan_item, :project, :blank
    assert_error @plan_item, :order_number, :blank
    assert_error @plan_item, :start, :invalid_date
    assert_error @plan_item, :end, :invalid_date

    if SHOW_REVIEW_EXTRA_ATTRIBUTES
      assert_error @plan_item, :scope, :blank
      assert_error @plan_item, :risk_exposure, :blank
    end
  end

  test 'validates length of attributes' do
    @plan_item.project = 'abcdd' * 52

    assert @plan_item.invalid?
    assert_error @plan_item, :project, :too_long, count: 255
  end

  test 'validates duplicated attributes' do
    plan_item = @plan_item.dup

    assert plan_item.invalid?
    assert_error plan_item, :project, :taken
  end

  test 'validates relative date attributes' do
    @plan_item.end = @plan_item.start.yesterday

    assert @plan_item.invalid?
    assert_error @plan_item, :end, :on_or_after, restriction: I18n.l(@plan_item.start)
  end

  test 'validates date in period attributes' do
    @plan_item.start = @plan_item.plan.period.start.yesterday
    @plan_item.end = @plan_item.plan.period.end.tomorrow

    assert @plan_item.invalid?
    assert_error @plan_item, :start, :out_of_period
    assert_error @plan_item, :end, :out_of_period
  end

  test 'resource overload' do
    plan_item_3 = plan_items :current_plan_item_3

    assert plan_item_3.valid?

    plan_item_3.resource_utilizations << @plan_item.human_resource_utilizations.first
    plan_item_3.start = @plan_item.end

    assert plan_item_3.invalid?
    assert_error plan_item_3, :start, :resource_overload
  end

  test 'units function' do
    units = @plan_item.resource_utilizations.map(&:units).compact.sum

    assert units > 0
    assert_equal units, @plan_item.units
  end

  test 'should return blank unused because period not have plan item unused' do
    assert PlanItem.list_unused((periods :third_period).id).blank?
  end

  test 'should return blank unused because free plan item dont have business unit' do
    assert PlanItem.list_unused((periods :current_period).id).blank?
  end

  test 'should return blank unused because current user dont have business_unit' do
    Current.user = users :poll

    PlanItem.create!(
      project: 'free plan item',
      start: 10.days.ago.to_date.to_s(:db),
      end: 10.days.from_now.to_date.to_s(:db),
      order_number: 7,
      scope: users(:committee),
      risk_exposure: 'high',
      plan: plans(:current_plan),
      business_unit: business_units(:business_unit_three)
    )

    assert PlanItem.list_unused((periods :current_period).id).blank?
  end

  test 'should return unused plan item' do
    new_plan_item = PlanItem.create!(
      project: 'free plan item',
      start: 10.days.ago.to_date.to_s(:db),
      end: 10.days.from_now.to_date.to_s(:db),
      order_number: 7,
      scope: users(:committee),
      risk_exposure: 'high',
      plan: plans(:current_plan),
      business_unit: business_units(:business_unit_three)
    )

    reponse = PlanItem.list_unused((periods :current_period).id)

    assert reponse.present?
    assert reponse.include?(new_plan_item)
  end

  test 'completed_early status' do
    @plan_item.start = 1.day.from_now.to_date
    @plan_item.end = 2.day.from_now.to_date
    @plan_item.conclusion_final_review.issue_date = 1.day.ago.to_date

    assert @plan_item.completed_early?
  end

  test 'completed status' do
    assert_equal @plan_item.completed?, @plan_item.conclusion_final_review
  end

  test 'in_early_progress status' do
    plan_item_3 = plan_items :current_plan_item_3

    assert plan_item_3.valid?
    assert plan_item_3.in_early_progress?
  end

  test 'in_progress_no_delayed status' do
    plan_item_2 = plan_items :current_plan_item_2

    assert plan_item_2.valid?
    assert plan_item_2.in_progress_no_delayed?
  end

  test 'overdue status' do
    plan_item_3 = plan_items :current_plan_item_3
    plan_item_3.start = 2.day.ago.to_date
    plan_item_3.end = 1.day.ago.to_date

    assert_nil plan_item_3.conclusion_final_review
    assert plan_item_3.valid?
    assert plan_item_3.overdue?
  end

  test 'not_started_no_delayed status' do
    plan_item_6 = plan_items :current_plan_item_6
    plan_item_6.start = 1.day.from_now.to_date

    assert plan_item_6.valid?
    assert_nil plan_item_6.review
    assert plan_item_6.not_started_no_delayed?
  end

  test 'delayed_pat status' do
    plan_item_6 = plan_items :current_plan_item_6

    assert plan_item_6.valid?
    assert_nil plan_item_6.review
    assert plan_item_6.delayed_pat?
  end

  test 'progress' do
    plan_item_2 = plan_items :current_plan_item_2

    assert plan_item_2.valid?
    assert plan_item_2.review
    assert_equal plan_item_2.progress.to_i, plan_item_2.human_units_consumed.to_i

    plan_item_2.resource_utilizations[0].units = 6

    assert plan_item_2.valid?
    assert plan_item_2.review
    assert_equal plan_item_2.progress.to_i, plan_item_2.human_units.to_i

    plan_item_6 = plan_items :current_plan_item_6

    assert plan_item_6.valid?
    assert_nil plan_item_6.review
    assert_equal plan_item_6.progress.to_i, plan_item_6.human_units_consumed.to_i
    assert_equal @plan_item.progress.to_i, @plan_item.human_units.to_i
  end
end
