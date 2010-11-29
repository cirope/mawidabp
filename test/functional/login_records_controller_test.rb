require 'test_helper'

# Pruebas para el controlador de registros de ingreso
class LoginRecordsControllerTest < ActionController::TestCase
  fixtures :login_records

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {:id => login_records(:administrator_user_success_login_record).to_param}
    public_actions = []
    private_actions = [
      [:get, :index],
      [:get, :choose],
      [:get, :export_to_pdf],
      [:get, :show, id_param]
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t(:'message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end
  
  test 'choose an action' do
    perform_auth
    get :choose
    assert_response :success
    assert_select '#error_body', false
    assert_template 'login_records/choose'
  end

  test 'list login records' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:login_records)
    assert_select '#error_body', false
    assert_template 'login_records/index'
  end

  test 'list login records with search' do
    perform_auth
    get :index, :search => {
      :query => 'login data',
      :columns => ['user', 'data']
    }

    assert_response :success
    assert_not_nil assigns(:login_records)
    assert_equal 2, assigns(:login_records).size
    assert assigns(:login_records).all? { |lr| lr.data.match(/login data/i) }
    assert_select '#error_body', false
    assert_template 'login_records/index'
  end

  test 'show login record when search match only one result' do
    perform_auth
    get :index, :search => {
      :query => 'bare',
      :columns => ['user', 'data']
    }

    assert_redirected_to login_record_path(
      login_records(:bare_user_success_login_record))
    assert_not_nil assigns(:login_records)
    assert_equal 1, assigns(:login_records).size
  end

  test 'show login record' do
    perform_auth
    get :show, :id => login_records(:administrator_user_success_login_record).id
    assert_response :success
    assert_not_nil assigns(:login_record)
    assert_select '#error_body', false
    assert_template 'login_records/show'
  end

  test 'export to pdf' do
    perform_auth
    from_date = Date.today.at_beginning_of_month
    to_date = Date.today.at_end_of_month

    assert_nothing_raised(Exception) do
      get :export_to_pdf,
        :range => {:from_date => from_date, :to_date => to_date}
    end

    assert_redirected_to PDF::Writer.relative_path(
      I18n.t(:'login_record.pdf_list_name',
        :from_date => from_date.to_formatted_s(:db),
        :to_date => to_date.to_formatted_s(:db)), LoginRecord.table_name)
  end
end