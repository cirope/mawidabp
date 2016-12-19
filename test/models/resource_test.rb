require 'test_helper'

class ResourceTest < ActiveSupport::TestCase
  def setup
    set_organization

    @resource = resources :auditor_resource
  end

  test 'create' do
    assert_difference 'Resource.count' do
      Resource.create(
        name: 'New name',
        description: 'New description',
        resource_class: resource_classes(:human_resources)
      )
    end
  end

  test 'update' do
    assert @resource.update(description: 'Updated resource'),
      @resource.errors.full_messages.join('; ')
    assert_equal 'Updated resource', @resource.reload.description
  end

  test 'delete' do
    assert_difference 'Resource.count', -1 do
      # TODO unscoped current_organization
      User.unscoped { @resource.destroy }
    end
  end

  test 'validates blank attributes' do
    @resource.name = ''

    assert @resource.invalid?
    assert_error @resource, :name, :blank
  end

  test 'validates length of attributes' do
    @resource.name = 'abcdd' * 52

    assert @resource.invalid?
    assert_error @resource, :name, :too_long, count: 255
  end

  test 'validates duplicated attributes' do
    @resource.name = resources(:developer_resource).name

    assert @resource.invalid?
    assert_error @resource, :name, :taken
  end
end
