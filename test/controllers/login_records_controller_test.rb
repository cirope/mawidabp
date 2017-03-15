require 'test_helper'

class LoginRecordsControllerTest < ActionController::TestCase
  setup do
    login
  end

  test 'choose an action' do
    get :choose
    assert_response :success
    assert_template 'login_records/choose'
  end

  test 'list login records' do
    get :index
    assert_response :success
    assert_not_nil assigns(:login_records)
    assert_template 'login_records/index'
  end

  test 'list login records with search' do
    get :index, params: {
      search: { query: 'login data', columns: ['user', 'data'] }
    }

    assert_response :success
    assert_equal 2, assigns(:login_records).count
    assert assigns(:login_records).all? { |lr| lr.data.match(/login data/i) }
    assert_template 'login_records/index'
  end

  test 'show login record' do
    get :show, :params => {
      :id => login_records(:administrator_user_success_login_record).id
    }
    assert_response :success
    assert_not_nil assigns(:login_record)
    assert_template 'login_records/show'
  end

  test 'export to pdf' do
    from_date = Date.today.at_beginning_of_month
    to_date = Date.today.at_end_of_month

    assert_nothing_raised do
      get :index, params: {
        index: { from_date: from_date, to_date: to_date },
        format: :pdf
      }
    end

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('login_records.pdf_list_name', from_date: from_date.to_formatted_s(:db),
        to_date: to_date.to_formatted_s(:db)), LoginRecord.table_name)
  end
end
