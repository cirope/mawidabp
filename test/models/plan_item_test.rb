require 'test_helper'

class PlanItemTest < ActiveSupport::TestCase
  setup do
    @plan_item = plan_items :current_plan_item_1

    set_organization
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
end
