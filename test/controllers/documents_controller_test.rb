require 'test_helper'

class DocumentsControllerTest < ActionController::TestCase

  setup do
    @document = documents :audit_manual

    login
  end

  test 'should get index' do
    get :index
    assert_response :success
  end

  test 'should get index for tag' do
    get :index, params: { tag_id: tags(:manual).id }
    assert_response :success
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create document' do
    assert_difference ['Document.count', 'Tagging.count'] do
      post :create, params: {
        document: {
          name: 'New document',
          description: 'New description',
          file_model_attributes: {
            file: Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH, 'text/plain')
          },
          taggings_attributes: [
            {
              tag_id: tags(:manual).id
            }
          ]
        }
      }
    end

    assert_redirected_to document_url(assigns(:document))
  end

  test 'should show document' do
    get :show, params: { id: @document }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @document }
    assert_response :success
  end

  test 'should update document' do
    patch :update, params: {
      id: @document,
      document: { name: 'value' }
    }
    assert_redirected_to document_url(assigns(:document))
  end

  test 'should destroy document' do
    assert_difference 'Document.count', -1 do
      delete :destroy, params: { id: @document }
    end

    assert_redirected_to documents_url
  end

  test 'should download' do
    get :download, params: { id: @document }

    assert_redirected_to @document.file_model.file.url
  end

  test 'auto complete for tagging' do
    get :auto_complete_for_tagging, params: {
      q: 'man',
      kind: 'document',
      format: :json
    }
    assert_response :success

    tags = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, tags.size
    assert tags.all? { |t| t['label'].match /man/i }

    get :auto_complete_for_tagging, params: {
      q: 'x_none',
      kind: 'document',
      format: :json
    }
    assert_response :success

    tags = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, tags.size
  end
end
