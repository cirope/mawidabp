require 'test_helper'

# Pruebas para el controlador de registros de errores
class ErrorRecordsControllerTest < ActionController::TestCase
  fixtures :error_records

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {:id => error_records(:administrator_user_failed_attempt).to_param}
    public_actions = []
    private_actions = [
      [:get, :show, id_param],
      [:get, :index]
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to login_url
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end

  test 'list error records' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:error_records)
    assert_template 'error_records/index'
  end

  test 'list error records with search' do
    perform_auth
    get :index, :search => {
      :query => 'usefull',
      :columns => ['user', 'data']
    }

    assert_response :success
    assert_not_nil assigns(:error_records)
    assert_equal 2, assigns(:error_records).size
    assert assigns(:error_records).all? { |er| er.data.match(/usefull/i) }
    assert_template 'error_records/index'
  end

  test 'show error record when search match only one result' do
    perform_auth
    get :index, :search => {
      :query => 'wrong',
      :columns => ['user', 'data']
    }

    assert_redirected_to error_record_url(
      error_records(:wrong_user_failed_attempt))
    assert_not_nil assigns(:error_records)
    assert_equal 1, assigns(:error_records).size
  end

  test 'show error record' do
    perform_auth
    get :show, :id => error_records(:administrator_user_failed_attempt).id
    assert_response :success
    assert_not_nil assigns(:error_record)
    assert_template 'error_records/show'
  end

  test 'export to pdf' do
    perform_auth
    from_date = Date.today.at_beginning_of_month
    to_date = Date.today.at_end_of_month

    assert_nothing_raised do
      get :export_to_pdf,
        :range => {:from_date => from_date, :to_date => to_date}
    end

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('error_record.pdf_list_name',
        :from_date => from_date.to_formatted_s(:db),
        :to_date => to_date.to_formatted_s(:db)), ErrorRecord.table_name)
  end
end
