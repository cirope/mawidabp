require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  setup do
    @tag = tags :important

    login
  end

  test 'should get index' do
    get :index, params: { kind: @tag.kind }
    assert_response :success
  end

  test 'should get filtered index' do
    get :index, params: {
      kind: @tag.kind,
      q: @tag.name
    }, as: :json
    assert_response :success

    tags = JSON.parse @response.body

    assert_equal 1, tags.size
    assert_equal @tag.name, tags.first['name']
  end

  test 'should get new' do
    get :new, params: { kind: @tag.kind }
    assert_response :success
  end

  test 'should create tag' do
    kind = @tag.kind

    assert_difference 'Tag.where(kind: kind).count' do
      post :create, params: {
        kind: kind,
        tag: {
          name: 'Test tag',
          style: 'secondary',
          shared: false,
          obsolete: false,
          icon: 'tag'
        }
      }
    end

    assert_redirected_to tag_url(Tag.last, kind: kind)
  end

  test 'should create tag with nested tags' do
    kind = @tag.kind

    assert_difference 'Tag.where(kind: kind).count', 2 do
      post :create, params: {
        kind: kind,
        tag: {
          name: 'Test tag',
          style: 'secondary',
          shared: false,
          obsolete: false,
          icon: 'tag',
          children_attributes: {
            '0' => {
              name: 'Test nested tag'
            }
          }
        }
      }
    end

    assert_redirected_to tag_url(Tag.roots.last, kind: kind)
    assert_equal 1, Tag.roots.last.children.count
  end

  test 'should show tag' do
    get :show, params: {
      kind: @tag.kind,
      id: @tag
    }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: {
      kind: @tag.kind,
      id: @tag
    }
    assert_response :success
  end

  test 'should update tag' do
    patch :update, params: {
      kind: @tag.kind,
      id: @tag,
      tag: {
        name: 'Updated text tag'
      }
    }

    assert_redirected_to tag_url(@tag, kind: @tag.kind)
  end

  test 'should update tag and create nested tag' do
    assert_difference 'Tag.count', 1 do
      patch :update, params: {
        kind: @tag.kind,
        id: @tag,
        tag: {
          name: 'Updated text tag',
          children_attributes: {
            '0' => {
              name: 'New nested tag'
            }
          }
        }
      }
    end

    assert_redirected_to tag_url(@tag, kind: @tag.kind)
  end

  test 'should destroy tag' do
    tag = tags :extra

    assert_difference 'Tag.count', -1 do
      delete :destroy, params: {
        id: tag,
        kind: tag.kind
      }
    end

    assert_redirected_to tags_url(kind: tag.kind)
  end
end
