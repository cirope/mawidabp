require 'test_helper'

class PlanTest < ActiveSupport::TestCase
  setup do
    @plan = plans :current_plan

    set_organization
  end

  test 'create' do
    assert_difference 'Plan.count' do
      Plan.list.create(period_id: periods(:unused_period).id)
    end
  end

  test 'update' do
    assert @plan.save, @plan.errors.full_messages.join('; ')
  end

  test 'destroy' do
    plan = plans :unrelated_plan

    assert_difference 'Plan.count', -1 do
      plan.destroy
    end
  end

  test 'delete' do
    assert_no_difference 'Plan.count' do
      @plan.destroy
    end

    assert_not_equal 0, @plan.errors[:base].size
  end

  test 'validates blank attributes' do
    @plan.period_id = nil

    assert @plan.invalid?
    assert_error @plan, :period_id, :blank
  end

  test 'validates duplicated attributes' do
    plan = @plan.dup

    assert plan.invalid?
    assert_error plan, :period_id, :taken
  end

  test 'overloaded validation' do
    assert !@plan.overloaded?

    @plan.plan_items.last.overloaded = true

    assert @plan.overloaded?
  end

  test 'has duplication validation' do
    assert !@plan.has_duplication?

    @plan.plan_items.last.errors.add :project, :taken

    assert @plan.has_duplication?
  end

  test 'allow overload' do
    assert !@plan.allow_overload?

    @plan.allow_overload = ''

    assert !@plan.allow_overload?

    @plan.allow_overload = true

    assert @plan.allow_overload?

    @plan.allow_overload = '1'

    assert @plan.allow_overload?
  end

  test 'estimated amount for business unit type' do
    but_id = business_unit_types(:cycle).id
    plan_items = @plan.plan_items.for_business_unit_type(but_id)

    calculated_amount = plan_items.inject 0.0 do |sum, pi|
      sum + pi.human_units
    end

    assert_not_equal plan_items.size, @plan.plan_items.size
    assert calculated_amount > 0
    assert_equal calculated_amount, @plan.estimated_amount(but_id)
  end

  test 'pdf conversion' do
    FileUtils.rm @plan.absolute_pdf_path if File.exist?(@plan.absolute_pdf_path)

    assert_nothing_raised do
      @plan.to_pdf(organizations(:cirope), include_details: false)
    end

    assert File.exist?(@plan.absolute_pdf_path)
    assert File.size(@plan.absolute_pdf_path) > 0

    FileUtils.rm @plan.absolute_pdf_path
  end

  test 'detailed pdf conversion' do
    assert !@plan.plan_items.all? { |pi| pi.resource_utilizations.blank? }

    FileUtils.rm @plan.absolute_pdf_path if File.exist?(@plan.absolute_pdf_path)

    assert_nothing_raised do
      @plan.to_pdf(organizations(:cirope), include_details: true)
    end

    assert File.exist?(@plan.absolute_pdf_path)
    assert File.size(@plan.absolute_pdf_path) > 0

    FileUtils.rm @plan.absolute_pdf_path
  end

  test 'units' do
    units = @plan.plan_items.inject(0) { |sum, pi| sum + pi.human_units }

    assert units > 0
    assert_equal units, @plan.units
  end

  test 'clone from without period' do
    new_plan = Plan.new

    new_plan.clone_from @plan

    all_items_and_resources_are_equal = new_plan.plan_items.all? do |pi|
      new_plan.plan_items.any? do |npi|
        npi.resource_utilizations == pi.resource_utilizations
      end
    end

    assert new_plan.plan_items.size > 0
    assert new_plan.plan_items.any? { |pi| pi.resource_utilizations.size > 0 }
    assert_equal @plan.plan_items.size, new_plan.plan_items.size
    assert all_items_and_resources_are_equal
  end

  test 'clone from with period' do
    period       = periods :unused_period
    new_plan     = Plan.list.new period_id: period.id
    Current.user = users :supervisor

    new_plan.clone_from @plan

    all_plan_items_moved_to_new_period = new_plan.plan_items.all? do |pi|
      period.contains?(pi.start) && period.contains?(pi.end) &&
        !@plan.period.contains?(pi.start) && !@plan.period.contains?(pi.end)
    end

    all_items_and_resources_are_equal = new_plan.plan_items.all? do |pi|
      new_plan.plan_items.any? do |npi|
        npi.resource_utilizations == pi.resource_utilizations
      end
    end

    assert new_plan.plan_items.size > 0
    assert new_plan.plan_items.any? { |pi| pi.resource_utilizations.size > 0 }
    assert_equal @plan.plan_items.size, new_plan.plan_items.size
    assert all_plan_items_moved_to_new_period
    assert all_items_and_resources_are_equal
    assert new_plan.allow_duplication?
    assert new_plan.allow_overload?
    assert new_plan.valid?
  ensure
    Current.user = nil
  end

  test 'totals in progress report by status' do
    csv             = @plan.to_csv_prs(business_unit_type: @business_unit_type)
    rows            = CSV.parse csv.sub("\uFEFF", ''), col_sep: ';', force_quotes: true
    rows_transposed = rows.transpose

    rows.each do |row|
      assert_equal row[1..7].map(&:to_i).sum, row.last.to_i
    end

    rows_transposed.each do |row_t|
      assert_equal row_t[1..row_t.length - 2].map(&:to_i).sum, row_t.last.to_i
    end
  end

  test 'totals in progress report by hours' do
    csv  = @plan.to_csv_prh(business_unit_type: @business_unit_type)
    rows = CSV.parse csv.sub("\uFEFF", ''), col_sep: ';', force_quotes: true

    rows.transpose.each do |row_t|
      assert_equal row_t[1..row_t.length - 3].map(&:to_i).sum, row_t.last.to_i
    end
  end

  test 'percentages in progress report by status' do
    csv  = @plan.to_csv_prh(business_unit_type: @business_unit_type)
    rows = CSV.parse csv.sub("\uFEFF", ''), col_sep: ';', force_quotes: true

    rows.each do |row|
      percentage = row[1].to_i == 0 ? 0.0 : (row[2].to_f * 100 / row[1].to_f).round(2)

      assert_equal percentage, row.last.to_f
    end
  end
end
