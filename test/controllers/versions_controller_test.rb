require 'test_helper'

class VersionsControllerTest < ActionController::TestCase
  setup do
    @version = versions :important_version

    login
  end

  test 'get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:versions)
    assert_template 'versions/index'
  end

  test 'show version' do
    get :show, params: { id: @version }
    assert_response :success
    assert_not_nil assigns(:version)
    assert_select 'table.table'
    assert_template 'versions/show'
  end

  test 'download security changes report' do
    from = Date.today.at_beginning_of_month
    to = Date.today.at_end_of_month

    assert_nothing_raised do
      get :index, params: {
        index: { from_date: from, to_date: to }
      }, as: :pdf
    end

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('versions.pdf_list_name',
        from_date: from.to_s(:db), to_date: to.to_s(:db)
      ), PaperTrail::Version.table_name)
  end
end
