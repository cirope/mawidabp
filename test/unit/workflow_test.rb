require 'test_helper'

# Clase para probar el modelo "Workflow"
class WorkflowTest < ActiveSupport::TestCase
  fixtures :workflows, :periods, :reviews

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @workflow = Workflow.find workflows(:with_conclusion_workflow).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Workflow, @workflow
    assert_equal workflows(:with_conclusion_workflow).period_id,
      @workflow.period_id
    assert_equal workflows(:with_conclusion_workflow).review_id,
      @workflow.review_id
  end

  # Prueba la creación de un programa de trabajo
  test 'create' do
    assert_difference 'Workflow.count' do
      Workflow.create(
        :period_id => periods(:current_period).id,
        :review_id => reviews(:review_without_conclusion).id
      )
    end
  end

  # Prueba de actualización de un programa de trabajo
  test 'update' do
    assert @workflow.save, @workflow.errors.full_messages.join('; ')
  end

  # Prueba de eliminación de programas de trabajo
  test 'destroy' do
    assert_difference 'Workflow.count', -1 do
      @workflow.destroy
    end
  end

  test 'destroy with final review' do
    assert_no_difference 'Workflow.count' do
      Workflow.find(workflows(:past_workflow).id).destroy
    end
  end

  # Prueba que las validaciones del modelo se complan como es esperado
  test 'validates formated attributes' do
    @workflow.period_id = '?123'
    @workflow.review_id = '?123'
    assert @workflow.invalid?
    assert_equal 2, @workflow.errors.count
    assert_equal error_message_from_model(@workflow, :period_id, :not_a_number),
      @workflow.errors[:period_id]
    assert_equal error_message_from_model(@workflow, :review_id, :not_a_number),
      @workflow.errors[:review_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @workflow.period_id = nil
    @workflow.review_id = nil
    assert @workflow.invalid?
    assert_equal 2, @workflow.errors.count
    assert_equal error_message_from_model(@workflow, :period_id, :blank),
      @workflow.errors[:period_id]
    assert_equal error_message_from_model(@workflow, :review_id, :blank),
      @workflow.errors[:review_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @workflow.review_id = workflows(:past_workflow).review_id
    assert @workflow.invalid?
    assert_equal 2, @workflow.errors.count
    assert_equal error_message_from_model(@workflow, :review_id, :taken),
      @workflow.errors[:review_id]
    assert @workflow.errors.full_messages.include?(I18n.t(:'workflow.readonly'))
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'overloaded validation' do
    assert !@workflow.overloaded?

    @workflow.workflow_items.last.overloaded = true

    assert @workflow.overloaded?
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'allow overload' do
    assert !@workflow.allow_overload?

    @workflow.allow_overload = '0'

    assert !@workflow.allow_overload?

    @workflow.allow_overload = true

    assert @workflow.allow_overload?

    @workflow.allow_overload = '1'

    assert @workflow.allow_overload?
  end

  test 'can be modified' do
    uneditable_workflow = Workflow.find(workflows(:past_workflow).id)

    @workflow.period_id = periods(:current_period_second_organization).id

    assert !@workflow.is_frozen?
    assert @workflow.valid?

    assert uneditable_workflow.is_frozen?

    # Puede ser "modificado" porque no se ha actualizado ninguno de sus
    # atributos
    assert uneditable_workflow.valid?

    uneditable_workflow.period_id = periods(:past_period_second_organization).id

    # No puede ser actualizado porque se ha modificado un atributo
    assert !uneditable_workflow.valid?
    assert !uneditable_workflow.save

    assert_no_difference 'Review.count' do
      uneditable_workflow.destroy
    end
  end

  test 'pdf conversion' do
    if File.exist?(@workflow.absolute_pdf_path)
      FileUtils.rm @workflow.absolute_pdf_path
    end

    assert_nothing_raised(Exception) do
      @workflow.to_pdf(organizations(:default_organization))
    end

    assert File.exist?(@workflow.absolute_pdf_path)
    assert File.size(@workflow.absolute_pdf_path) > 0

    FileUtils.rm @workflow.absolute_pdf_path
  end

  test 'cost' do
    cost = @workflow.workflow_items.to_a.sum(&:cost)

    assert cost > 0
    assert_equal cost, @workflow.cost
  end
end