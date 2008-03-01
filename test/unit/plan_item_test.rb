require 'test_helper'

# Clase para probar el modelo "PlanItem"
class PlanItemTest < ActiveSupport::TestCase
  fixtures :plan_items, :plans, :business_units, :resources,
    :resource_utilizations

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @plan_item = PlanItem.find plan_items(:current_plan_item_1).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of PlanItem, @plan_item
    assert_equal plan_items(:current_plan_item_1).project, @plan_item.project
    assert_equal plan_items(:current_plan_item_1).start, @plan_item.start
    assert_equal plan_items(:current_plan_item_1).end, @plan_item.end
    assert_equal plan_items(:current_plan_item_1).predecessors,
      @plan_item.predecessors
    assert_equal plan_items(:current_plan_item_1).order_number,
      @plan_item.order_number
  end

  # Prueba la creación de un item de plan
  test 'create' do
    assert_difference 'PlanItem.count' do
      plan = Plan.find plans(:current_plan).id

      @plan_item = plan.plan_items.build(
        :project => 'New project',
        :start => 6.days.from_now.to_date,
        :end => 7.days.from_now.to_date,
        :plain_predecessors => '1, 3',
        :order_number => 4,
        :plan => plan,
        :business_unit => business_units(:business_unit_one)
      )
      
      assert @plan_item.save, @plan_item.errors.full_messages.join('; ')
    end
  end

  # Prueba de actualización de un item de plan
  test 'update' do
    assert @plan_item.update_attributes(:project => 'Updated project'),
      @plan_item.errors.full_messages.join('; ')
    @plan_item.reload
    assert_equal 'Updated project', @plan_item.project
  end

  test 'destroy' do
    assert_difference 'PlanItem.count', -1 do
      PlanItem.find(plan_items(:past_plan_item_3).id).destroy
    end
  end

  # Prueba de eliminación de items de planes
  test 'delete' do
    assert_no_difference('PlanItem.count') { @plan_item.destroy }

    assert_equal 1, @plan_item.errors.size
    assert_equal I18n.t(:'plan.errors.plan_item_related'),
      @plan_item.errors.full_messages.join
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @plan_item.order_number = '_1'
    @plan_item.plan_id = '_1'
    @plan_item.business_unit_id = '_1'
    @plan_item.start = '_1'
    @plan_item.end = '_1'
    assert @plan_item.invalid?
    assert_equal 5, @plan_item.errors.count
    assert_equal error_message_from_model(@plan_item, :order_number,
      :not_a_number), @plan_item.errors.on(:order_number)
    assert_equal error_message_from_model(@plan_item, :plan_id, :not_a_number),
      @plan_item.errors.on(:plan_id)
    assert_equal error_message_from_model(@plan_item, :business_unit_id,
      :not_a_number), @plan_item.errors.on(:business_unit_id)
    assert_equal error_message_from_model(@plan_item, :start, :invalid_date),
      @plan_item.errors.on(:start)
    assert_equal error_message_from_model(@plan_item, :end, :invalid_date),
      @plan_item.errors.on(:end)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @plan_item.reload
    @plan_item.project = nil
    @plan_item.order_number = nil
    @plan_item.start = nil
    @plan_item.end = '   '
    assert @plan_item.invalid?
    assert_equal 4, @plan_item.errors.count
    assert_equal error_message_from_model(@plan_item, :project, :blank),
      @plan_item.errors.on(:project)
    assert_equal error_message_from_model(@plan_item, :order_number, :blank),
      @plan_item.errors.on(:order_number)
    assert_equal error_message_from_model(@plan_item, :start, :blank),
      @plan_item.errors.on(:start)
    assert_equal error_message_from_model(@plan_item, :end, :blank),
      @plan_item.errors.on(:end)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    # Predecessors no se puede verificar porque se serializa
    @plan_item.project = 'abcdd' * 52
    assert @plan_item.invalid?
    assert_equal 1, @plan_item.errors.count
    assert_equal error_message_from_model(@plan_item, :project, :too_long,
      :count => 255), @plan_item.errors.on(:project)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @plan_item.project = plan_items(:current_plan_item_2).project
    assert @plan_item.invalid?
    assert_equal 1, @plan_item.errors.count
    assert_equal error_message_from_model(@plan_item, :project, :taken),
      @plan_item.errors.on(:project)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates relative date attributes' do
    @plan_item.end = @plan_item.start.yesterday
    assert @plan_item.invalid?
    assert_equal 1, @plan_item.errors.count
    assert_equal error_message_from_model(@plan_item, :end, :on_or_after,
      :restriction => I18n.l(@plan_item.start)), @plan_item.errors.on(:end)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates date in period attributes' do
    @plan_item.start = @plan_item.plan.period.start.yesterday
    @plan_item.end = @plan_item.plan.period.end.tomorrow
    assert @plan_item.invalid?
    assert_equal 2, @plan_item.errors.count
    assert_equal error_message_from_model(@plan_item, :start, :out_of_period),
      @plan_item.errors.on(:start)
    assert_equal error_message_from_model(@plan_item, :end, :out_of_period),
      @plan_item.errors.on(:end)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'item overload' do
    @plan_item = PlanItem.find plan_items(:current_plan_item_2).id
    @plan_item.start = plan_items(:current_plan_item_1).start
    @plan_item.end = plan_items(:current_plan_item_1).end.yesterday
    assert @plan_item.invalid?
    assert_equal 2, @plan_item.errors.count
    assert_equal error_message_from_model(@plan_item, :end, :item_overload),
      @plan_item.errors.on(:end)
    assert_equal error_message_from_model(@plan_item, :start, :item_overload),
      @plan_item.errors.on(:start)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'resource overload' do
    plan_item_3 = PlanItem.find plan_items(:current_plan_item_3).id
    
    assert plan_item_3.valid?

    plan_item_3.resource_utilizations <<
      @plan_item.human_resource_utilizations.first
    plan_item_3.start = @plan_item.end

    assert plan_item_3.invalid?
    assert_equal 1, plan_item_3.errors.count
    assert_equal error_message_from_model(plan_item_3, :start,
      :resource_overload), plan_item_3.errors.on(:start)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'predecessors validation' do
    @plan_item.plain_predecessors = '100'
    assert @plan_item.invalid?
    assert_equal 1, @plan_item.errors.count
    assert_equal error_message_from_model(@plan_item, :predecessors, :invalid),
      @plan_item.errors.on(:predecessors)
  end

  test 'cost function' do
    cost = @plan_item.resource_utilizations.inject(0) {|sum, ru| sum + ru.cost}

    assert cost > 0
    assert_equal cost, @plan_item.cost
  end
end