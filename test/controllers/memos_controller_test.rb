require 'test_helper'

class MemosControllerTest < ActionController::TestCase
  setup do
    skip unless SHOW_MEMOS

    @memo = memos :first_memo

    login
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:memos)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create memo' do
    assert_difference ['Memo.count', 'FileModelMemo.count', 'FileModel.count'] do
      post :create, params: {
        memo: {
          period_id: periods(:current_period).id,
          plan_item_id: plan_items(:current_plan_item_4_without_business_unit).id,
          name: 'Second Memo',
          description: 'description',
          required_by: '',
          manual_required_by: '1',
          required_by_text: 'test required by',
          close_date: 15.days.from_now.to_date.to_s(:db),
          file_model_memos_attributes: [
            file_model_attributes: {
              file: File.open(TEST_FILE_FULL_PATH)
            }
          ]
        }
      }
    end

    assert_redirected_to edit_memo_url(Memo.last)
    assert_equal I18n.t('memo.correctly_created'), flash[:notice]
  end

  test 'should show memo' do
    get :show, params: { id: @memo }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @memo }
    assert_response :success
  end

  test 'should update memo' do
    patch :update, params: {
      id: @memo.id,
      memo: {
        name: 'Memo updated',
        description: 'description updated',
        required_by: '',
        manual_required_by: '1',
        required_by_text: 'test required by',
        close_date: 17.days.from_now.to_date.to_s(:db),
        file_model_memos_attributes: [
          file_model_attributes: {
            file: File.open(TEST_FILE_FULL_PATH)
          }
        ]
      }
    }

    assert_redirected_to edit_memo_url(@memo)
    assert_equal I18n.t('memo.correctly_updated'), flash[:notice]
  end

  test 'should plan items refresh' do
    get :plan_item_refresh, params: {
      period_id: periods(:current_period).id
    }, xhr: true, as: :js

    assert_response :success
    assert_match Mime[:js].to_s, @response.content_type
  end

  test 'export memo to pdf' do
    assert_nothing_raised do
      get :export_to_pdf, params: { id: @memo.id }
    end

    assert_redirected_to @memo.relative_pdf_path
  end
end
