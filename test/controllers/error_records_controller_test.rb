require 'test_helper'

class ErrorRecordsControllerTest < ActionController::TestCase
  setup do
    login
  end

  test 'list error records' do
    get :index
    assert_response :success
    assert_not_nil assigns(:error_records)
    assert_template 'error_records/index'
  end

  test 'list error records with search' do
    get :index, search: { query: 'usefull', columns: ['user', 'data'] }

    assert_response :success
    assert_equal 2, assigns(:error_records).count
    assert assigns(:error_records).all? { |er| er.data.match(/usefull/i) }
    assert_template 'error_records/index'
  end

  test 'show error record' do
    get :show, id: error_records(:administrator_user_failed_attempt).id

    assert_response :success
    assert_not_nil assigns(:error_record)
    assert_template 'error_records/show'
  end

  test 'export to pdf' do
    from = Date.today.at_beginning_of_month
    to = Date.today.at_end_of_month

    assert_nothing_raised do
      get :index, index: { from_date: from, to_date: to }, format: :pdf
    end

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('error_records.pdf_list_name',
        from_date: from.to_s(:db), to_date: to.to_s(:db)),
      ErrorRecord.table_name)
  end
end
