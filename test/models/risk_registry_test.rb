require 'test_helper'

class RiskRegistryTest < ActiveSupport::TestCase
  setup do
    @risk_registry = risk_registries :risk_registry

    set_organization
  end

  test 'create' do
    assert_difference 'RiskRegistry.count' do
      @risk_registry = RiskRegistry.create(
        name: 'New name',
        description: 'New description'
      )
    end

    assert_equal organizations(:cirope).id,
      @risk_registry.organization_id
  end

  test 'update' do
    assert @risk_registry.update(name: 'Updated name'),
      @risk_registry.errors.full_messages.join('; ')

    assert_equal 'Updated name', @risk_registry.reload.name
  end

  test 'destroy' do
    assert_difference 'RiskRegistry.count', -1 do
      risk_registries(:risk_registry).destroy
    end
  end

  test 'destroy with asociated risks' do
    assert_no_difference 'BestPractice.count' do
      @risk_registry.destroy
    end

    assert_equal 1, @risk_registry.errors.size
  end

  test 'blank attributes' do
    @risk_registry.name = ''
    @risk_registry.group_id = nil
    @risk_registry.organization_id = nil

    assert @risk_registry.invalid?
    assert_error @risk_registry, :name, :blank
    assert_error @risk_registry, :organization_id, :blank
    assert_error @risk_registry, :group_id, :blank
  end

  test 'validates length of attributes' do
    @risk_registry.name = 'abcdd' * 52

    assert @risk_registry.invalid?
    assert_error @risk_registry, :name, :too_long, count: 255
  end

  test 'unique attributes' do
    risk_registry = @risk_registry.dup

    assert risk_registry.invalid?
    assert_error risk_registry, :name, :taken
  end
end
