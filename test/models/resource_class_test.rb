require 'test_helper'

class ResourceClassTest < ActiveSupport::TestCase
  def setup
    set_organization

    @resource_class = resource_classes :human_resources
  end

  test 'create' do
    assert_difference 'ResourceClass.count' do
      ResourceClass.list.create(
        name: 'New resource class',
        resource_class_type: ResourceClass::TYPES[:human],
        organization: organizations(:cirope)
      )
    end
  end

  test 'update' do
    assert @resource_class.update(name: 'Updated resource_class'),
      @resource_class.errors.full_messages.join('; ')

    assert_equal 'Updated resource_class', @resource_class.reload.name
  end

  test 'delete' do
    assert_difference 'ResourceClass.count', -1 do
      # TODO unscoped current_organization
      User.unscoped { @resource_class.destroy }
    end
  end

  test 'validates formated attributes' do
    @resource_class.name = '?_1'

    assert @resource_class.invalid?
    assert_error @resource_class, :name, :invalid
  end

  test 'validates blank attributes' do
    @resource_class.name = nil

    assert @resource_class.invalid?
    assert_error @resource_class, :name, :blank
  end

  test 'validates length of attributes' do
    @resource_class.name = 'abcdd' * 52

    assert @resource_class.invalid?
    assert_error @resource_class, :name, :too_long, count: 255
  end

  test 'validates duplicated attributes' do
    @resource_class.name = resource_classes(:hardware_resources).name

    assert @resource_class.invalid?
    assert_error @resource_class, :name, :taken

    @resource_class.organization_id = organizations(:google).id
    assert @resource_class.valid?
  end

  test 'validates included attributes' do
    @resource_class.resource_class_type =
      ResourceClass::TYPES.values.sort.last.next

    assert @resource_class.invalid?
    assert_error @resource_class, :resource_class_type, :inclusion
  end

  test 'dynamic functions' do
    ResourceClass::TYPES.each do |type, value|
      @resource_class.resource_class_type = value
      assert @resource_class.send("#{type}?".to_sym)

      (ResourceClass::TYPES.values - [value]).each do |v|
        @resource_class.resource_class_type = v
        assert !@resource_class.send("#{type}?".to_sym)
      end
    end
  end
end
