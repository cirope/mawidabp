require 'test_helper'

# Clase para probar el modelo "Period"
class PeriodTest < ActiveSupport::TestCase
  fixtures :periods, :organizations

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @period = Period.find periods(:current_period).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Period, @period
    assert_equal periods(:current_period).number, @period.number
    assert_equal periods(:current_period).description, @period.description
    assert_equal periods(:current_period).start, @period.start
    assert_equal periods(:current_period).end, @period.end
  end

  # Prueba la creación de un periodo
  test 'create' do
    assert_difference 'Period.count' do
      Period.create(
        :number => '20',
        :description => 'New period',
        :start => 2.months.from_now.to_date, # Administrador
        :end => 3.months.from_now.to_date,
        :organization => organizations(:default_organization)
      )
    end
  end

  # Prueba de actualización de un periodo
  test 'update' do
    assert @period.update_attributes(:description => 'Updated period'),
      @period.errors.full_messages.join('; ')
    @period.reload
    assert_equal 'Updated period', @period.description
  end

  # Prueba de eliminación de periodos
  test 'destroy' do
    assert_difference 'Period.count', -1 do
      Period.find(periods(:unused_period).id).destroy
    end
  end

  test 'destroy asociated period' do
    assert_no_difference('Period.count') { @period.destroy }

    assert_equal 4, @period.errors.size
    assert_equal [
      I18n.t(:'period.errors.has_reviews', :count => @period.reviews.size),
      I18n.t(:'period.errors.has_plans', :count => @period.plans.size),
      I18n.t(:'period.errors.has_workflows', :count => @period.workflows.size),
      I18n.t(:'period.errors.has_procedure_controls',
        :count => @period.procedure_controls.size)].sort,
      @period.errors.full_messages.sort
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @period.number = '_1'
    @period.start = '_1'
    @period.end = '_1'
    assert @period.invalid?
    assert_equal 5, @period.errors.count
    assert_equal [error_message_from_model(@period, :number, :not_a_number)],
      @period.errors[:number]
    assert_equal [error_message_from_model(@period, :start, :invalid_date),
      error_message_from_model(@period, :start, :blank)].sort,
      @period.errors[:start].sort
    assert_equal [error_message_from_model(@period, :end, :invalid_date),
      error_message_from_model(@period, :end, :blank)].sort,
      @period.errors[:end].sort
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @period.number = nil
    @period.start = nil
    @period.end = '   '
    @period.description = nil
    @period.organization_id = nil
    assert @period.invalid?
    assert_equal 5, @period.errors.count
    assert_equal [error_message_from_model(@period, :number, :blank)],
      @period.errors[:number]
    assert_equal [error_message_from_model(@period, :start, :blank)],
      @period.errors[:start]
    assert_equal [error_message_from_model(@period, :end, :blank)],
      @period.errors[:end]
    assert_equal [error_message_from_model(@period, :description, :blank)],
      @period.errors[:description]
    assert_equal [error_message_from_model(@period, :organization_id, :blank)],
      @period.errors[:organization_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates relative date attributes' do
    @period.end = @period.start.yesterday
    assert @period.invalid?
    assert_equal 1, @period.errors.count
    assert_equal [error_message_from_model(@period, :end, :after,
      :restriction => I18n.l(@period.start))], @period.errors[:end]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @period.number = periods(:past_period).number
    assert @period.invalid?
    assert_equal 1, @period.errors.count
    assert_equal [error_message_from_model(@period, :number, :taken)],
      @period.errors[:number]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates integer number format' do
    @period.number = 1.5
    assert @period.invalid?
    assert_equal 1, @period.errors.count
    assert_equal [error_message_from_model(@period, :number, :not_an_integer)],
      @period.errors[:number]
  end
end