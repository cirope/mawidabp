require 'test_helper'

# Clase para probar el modelo "WorkflowItem"
class WorkflowItemTest < ActiveSupport::TestCase
  fixtures :workflow_items, :workflows, :control_objective_items, :resources
  
  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    set_organization

    @workflow_item = WorkflowItem.find(
      workflow_items(:with_conclusion_workflow_item_1).id)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of WorkflowItem, @workflow_item
    assert_equal workflow_items(:with_conclusion_workflow_item_1).task,
      @workflow_item.task
    assert_equal workflow_items(:with_conclusion_workflow_item_1).start,
      @workflow_item.start
    assert_equal workflow_items(:with_conclusion_workflow_item_1).end,
      @workflow_item.end
    assert_equal workflow_items(:with_conclusion_workflow_item_1).predecessors,
      @workflow_item.predecessors
    assert_equal workflow_items(:with_conclusion_workflow_item_1).order_number,
      @workflow_item.order_number
  end

  # Prueba la creación de un item de plan de trabajo
  test 'create' do
    assert_difference 'WorkflowItem.count' do
      workflow = Workflow.find workflows(:with_conclusion_workflow).id

      @workflow_item = workflow.workflow_items.build(
        :task => 'New task',
        :start => 6.days.from_now.to_date,
        :end => 7.days.from_now.to_date,
        :plain_predecessors => '1, 3',
        :order_number => 4,
        :workflow => workflow
      )

      assert @workflow_item.save, @workflow_item.errors.full_messages.join('; ')
    end
  end

  # Prueba de actualización de un item de plan de trabajo
  test 'update' do
    assert @workflow_item.update(:task => 'Updated task'),
      @workflow_item.errors.full_messages.join('; ')
    @workflow_item.reload
    assert_equal 'Updated task', @workflow_item.task
  end

  # Prueba de eliminación de items de planes de trabajo
  test 'destroy' do
    assert_difference 'WorkflowItem.count', -1 do
      @workflow_item.destroy
    end
  end

  test 'destroy with final review' do
    assert_no_difference 'WorkflowItem.count' do
      WorkflowItem.find(workflow_items(:past_workflow_item_1).id).destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @workflow_item.order_number = '_1'
    @workflow_item.workflow_id = '_1'
    @workflow_item.start = '_1'
    @workflow_item.end = '_1'

    assert @workflow_item.invalid?
    assert_error @workflow_item, :order_number, :not_a_number
    assert_error @workflow_item, :workflow_id, :not_a_number
    assert_error @workflow_item, :start, :invalid_date
    assert_error @workflow_item, :end, :invalid_date
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @workflow_item.reload
    @workflow_item.task = nil
    @workflow_item.order_number = nil
    @workflow_item.start = nil
    @workflow_item.end = '   '

    assert @workflow_item.invalid?
    assert_error @workflow_item, :task, :blank
    assert_error @workflow_item, :order_number, :blank
    assert_error @workflow_item, :start, :invalid_date
    assert_error @workflow_item, :end, :invalid_date
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @workflow_item.task = workflow_items(:with_conclusion_workflow_item_2).task

    assert @workflow_item.invalid?
    assert_error @workflow_item, :task, :taken
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates relative date attributes' do
    @workflow_item.end = @workflow_item.start.yesterday

    assert @workflow_item.invalid?
    assert_error @workflow_item, :end, :on_or_after, restriction: I18n.l(@workflow_item.start)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates date in period attributes' do
    @workflow_item.start = @workflow_item.workflow.period.start.yesterday
    @workflow_item.end = @workflow_item.workflow.period.end.tomorrow

    assert @workflow_item.invalid?
    assert_error @workflow_item, :start, :out_of_period
    assert_error @workflow_item, :end, :out_of_period
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'item overload' do
    @workflow_item = WorkflowItem.find(
      workflow_items(:with_conclusion_workflow_item_2).id)
    @workflow_item.start =
      workflow_items(:with_conclusion_workflow_item_1).start
    @workflow_item.end =
      workflow_items(:with_conclusion_workflow_item_1).end.yesterday

    assert @workflow_item.invalid?
    assert_error @workflow_item, :start, :item_overload
    assert_error @workflow_item, :end, :item_overload
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'resource overload' do
    workflow_item_3 = WorkflowItem.find(
      workflow_items(:current_workflow_item_3).id)

    assert workflow_item_3.valid?

    workflow_item_3.resource_utilizations <<
      @workflow_item.reload.human_resource_utilizations.first
    workflow_item_3.start = @workflow_item.end

    assert workflow_item_3.invalid?
    assert_error workflow_item_3, :start, :resource_overload
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'predecessors validation' do
    @workflow_item.plain_predecessors = '100'

    assert @workflow_item.invalid?
    assert_error @workflow_item, :predecessors, :invalid
  end

  test 'can be modified' do
    uneditable_workflow_item = WorkflowItem.find(
      workflow_items(:past_workflow_item_1).id)

    @workflow_item.task = 'Updated task'

    assert !@workflow_item.is_frozen?
    assert @workflow_item.valid?

    assert uneditable_workflow_item.is_frozen?

    # Puede ser "modificado" porque no se ha actualizado ninguno de sus
    # atributos
    assert uneditable_workflow_item.valid?

    uneditable_workflow_item.task = 'Updated task'

    # No puede ser actualizado porque se ha modificado un atributo
    assert !uneditable_workflow_item.valid?
    assert !uneditable_workflow_item.save

    assert_no_difference 'WorkflowItem.count' do
      uneditable_workflow_item.destroy
    end
  end

  test 'cost function' do
    cost = @workflow_item.resource_utilizations.inject(0) do |sum, ru|
      sum + ru.cost
    end

    assert cost > 0
    assert_equal cost, @workflow_item.cost
  end
end
