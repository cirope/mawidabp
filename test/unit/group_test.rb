require 'test_helper'

# Clase para probar el modelo "Group"
class GroupTest < ActiveSupport::TestCase
  fixtures :groups

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @group = Group.find groups(:main_group).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Group, @group
    assert_equal groups(:main_group).name, @group.name
    assert_equal groups(:main_group).admin_email, @group.admin_email
    assert_equal groups(:main_group).description, @group.description
  end

  # Prueba la creación de un grupo
  test 'create' do
    assert_difference 'Group.count' do
      @group = Group.create(
        :name => 'New name',
        :description => 'New description',
        :admin_email => 'new_group@test.com'
      )
    end
  end

  # Prueba de actualización de un grupo
  test 'update' do
    assert @group.update(:name => 'Updated name'),
      @group.errors.full_messages.join('; ')
    @group.reload
    assert_equal 'Updated name', @group.name
  end

  # Prueba de eliminación de un grupo
  test 'delete' do
    group = Group.find(Group.find groups(:second_group).id)
    
    assert_difference('Group.count', -1) { group.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @group.name = ' '
    @group.admin_email = ' '
    assert @group.invalid?
    assert_equal 2, @group.errors.count
    assert_equal [error_message_from_model(@group, :name, :blank)],
      @group.errors[:name]
    assert_equal [error_message_from_model(@group, :admin_email, :blank)],
      @group.errors[:admin_email]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @group.name = 'abcdd' * 52
    @group.admin_hash = 'abcdd' * 52
    @group.admin_email = "#{'abcdd' * 20}@test.com"
    assert @group.invalid?
    assert_equal 3, @group.errors.count
    assert_equal [error_message_from_model(@group, :name, :too_long,
      :count => 255)], @group.errors[:name]
    assert_equal [error_message_from_model(@group, :admin_hash, :too_long,
      :count => 255)], @group.errors[:admin_hash]
    assert_equal [error_message_from_model(@group, :admin_email, :too_long,
      :count => 100)], @group.errors[:admin_email]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @group.name = groups(:second_group).name
    @group.admin_email = groups(:second_group).admin_email
    assert @group.invalid?
    assert_equal 2, @group.errors.count
    assert_equal [error_message_from_model(@group, :name, :taken)],
      @group.errors[:name]
    assert_equal [error_message_from_model(@group, :admin_email, :taken)],
      @group.errors[:admin_email]
  end

  test 'send group welcome email' do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_no_difference "ActionMailer::Base.deliveries.size" do
      @group.send_notification_email = false

      assert @group.save
    end

    assert_difference "ActionMailer::Base.deliveries.size" do
      @group.admin_hash = nil
      @group.send_notification_email = true
      
      assert @group.save
      assert_not_nil @group.admin_hash
    end
  end
end
