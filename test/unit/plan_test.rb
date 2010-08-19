require 'test_helper'

# Clase para probar el modelo "Plan"
class PlanTest < ActiveSupport::TestCase
  fixtures :plans, :organizations, :periods

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @plan = Plan.find plans(:current_plan).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Plan, @plan
    assert_equal plans(:current_plan).period_id, @plan.period_id
  end

  # Prueba la creación de un plan de trabajo
  test 'create' do
    assert_difference 'Plan.count' do
      Plan.create(:period_id => periods(:unused_period).id)
    end
  end

  # Prueba de actualización de un plan de trabajo
  test 'update' do
    assert @plan.save, @plan.errors.full_messages.join('; ')
  end

  # Prueba de eliminación de planes de trabajo
  test 'destroy' do
    assert_difference 'Plan.count', -1 do
      Plan.find(plans(:unrelated_plan).id).destroy
    end
  end

  # Prueba de eliminación de planes de trabajo
  test 'delete' do
    assert_no_difference('Plan.count') { @plan.destroy }

    assert_equal 1, @plan.errors.size
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @plan.period_id = '?123'
    assert @plan.invalid?
    assert_equal 1, @plan.errors.count
    assert_equal error_message_from_model(@plan, :period_id, :not_a_number),
      @plan.errors.on(:period_id)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @plan.period_id = nil
    assert @plan.invalid?
    assert_equal 1, @plan.errors.count
    assert_equal error_message_from_model(@plan, :period_id, :blank),
      @plan.errors.on(:period_id)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @plan.period_id = plans(:past_plan).period_id
    assert @plan.invalid?
    assert_not_equal 0, @plan.errors.count
    assert_equal error_message_from_model(@plan, :period_id, :taken),
      @plan.errors.on(:period_id)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
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

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'allow overload' do
    assert !@plan.allow_overload?

    @plan.allow_overload = '0'

    assert !@plan.allow_overload?

    @plan.allow_overload = true

    assert @plan.allow_overload?

    @plan.allow_overload = '1'

    assert @plan.allow_overload?
  end

  test 'estimated amount' do
    calculated_amount = @plan.plan_items.inject(0) do |sum, pi|
      sum + pi.resource_utilizations.inject(0) {|t, ru| t + ru.cost}
    end

    assert calculated_amount > 0
    assert_equal calculated_amount, @plan.estimated_amount
  end

  test 'pdf conversion' do
    FileUtils.rm @plan.absolute_pdf_path if File.exist?(@plan.absolute_pdf_path)

    assert_nothing_raised(Exception) do
      @plan.to_pdf(organizations(:default_organization), false)
    end

    assert File.exist?(@plan.absolute_pdf_path)
    assert File.size(@plan.absolute_pdf_path) > 0

    FileUtils.rm @plan.absolute_pdf_path
  end

  test 'detailed pdf conversion' do
    assert !@plan.plan_items.all? { |pi| pi.resource_utilizations.blank? }

    FileUtils.rm @plan.absolute_pdf_path if File.exist?(@plan.absolute_pdf_path)

    assert_nothing_raised(Exception) do
      @plan.to_pdf(organizations(:default_organization), true)
    end

    assert File.exist?(@plan.absolute_pdf_path)
    assert File.size(@plan.absolute_pdf_path) > 0

    FileUtils.rm @plan.absolute_pdf_path
  end

  test 'cost' do
    cost = @plan.plan_items.inject(0) { |sum, pi| sum + pi.cost }

    assert cost > 0
    assert_equal cost, @plan.cost
  end

  test 'clone from' do
    new_plan = Plan.new
    new_plan.clone_from(@plan)

    assert new_plan.plan_items.size > 0
    assert new_plan.plan_items.any? { |pi| pi.resource_utilizations.size > 0 }
    assert_equal @plan.plan_items, new_plan.plan_items
    assert @plan.plan_items.all? { |pi|
      new_plan.plan_items.any? { |npi|
        npi.resource_utilizations == pi.resource_utilizations
      }
    }
  end
end