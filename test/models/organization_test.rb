require 'test_helper'

class OrganizationTest < ActiveSupport::TestCase
  fixtures :organizations

  setup do
    @organization = organizations :cirope

    set_organization
  end

  test 'create' do
    assert_difference 'Organization.count' do
      assert_difference 'Setting.count', DEFAULT_SETTINGS.size do
        assert_difference 'Role.count', Role::TYPES.size do
          @organization = Organization.create(
            name: 'new3 organization',
            prefix: 'newww-test-prefix'
          )
        end
      end
    end

    assert_equal groups(:main_group).id, @organization.reload.group_id
  end

  test 'create with wrong group' do
    assert_difference 'Organization.count' do
      assert_difference 'Setting.count', DEFAULT_SETTINGS.size do
        assert_difference 'Role.count', Role::TYPES.size do
          @organization = Organization.create(
            name: 'new3 organization',
            prefix: 'newww-test-prefix',
            group_id: groups(:second_group).id
          )
        end
      end
    end

    assert_equal groups(:main_group).id, @organization.reload.group_id
  end

  test 'update' do
    assert @organization.update(name: 'New name')
    @organization.reload
    assert_equal 'New name', @organization.name
  end

  test 'destroy' do
    organization = organizations :google

    assert_difference ['ImageModel.count', 'Organization.count'], -1 do
      organization.destroy
    end
  end

  test 'cancel destroy' do
    assert_no_difference 'Organization.count' do
      @organization.destroy
    end
  end

  test 'validates blank attributes' do
    @organization.name = nil
    @organization.prefix = nil

    assert @organization.invalid?
    assert_error @organization, :name, :blank
    assert_error @organization, :prefix, :blank
  end

  test 'validates length of attributes' do
    @organization.name = 'abcdd' * 52
    @organization.prefix = 'abcdd' * 52

    assert @organization.invalid?
    assert_error @organization, :name, :too_long, count: 255
    assert_error @organization, :prefix, :too_long, count: 255
  end

  test 'validates formated attributes' do
    @organization.prefix = '?123'

    assert @organization.invalid?
    assert_error @organization, :prefix, :invalid

    @organization.prefix = 'abc_abc'

    assert @organization.invalid?
    assert_error @organization, :prefix, :invalid
  end

  test 'validates duplicated attributes' do
    organization = @organization.dup

    assert organization.invalid?
    assert_error organization, :name, :taken
    assert_error organization, :prefix, :taken

    organization.group_id = groups(:second_group).id

    assert organization.invalid?
    assert_error organization, :prefix, :taken
  end

  test 'validates excluded attributes' do
    @organization.prefix = APP_ADMIN_PREFIXES.first

    assert @organization.invalid?
    assert_error @organization, :prefix, :exclusion
  end
end
