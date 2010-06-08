require 'test_helper'

# Clase para probar el modelo "User"
class UserTest < ActiveSupport::TestCase
  fixtures :users, :roles, :privileges

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @user = User.find users(:administrator_second_user).id
    GlobalModelConfig.current_organization_id =
      organizations(:default_organization).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of User, @user
    assert_equal users(:administrator_second_user).name, @user.name
    assert_equal users(:administrator_second_user).last_name, @user.last_name
    assert_equal users(:administrator_second_user).language, @user.language
    assert_equal users(:administrator_second_user).email, @user.email
    assert_equal users(:administrator_second_user).function, @user.function
    assert_equal users(:administrator_second_user).user, @user.user
    assert_equal users(:administrator_second_user).password, @user.password
    assert_equal users(:administrator_second_user).enable, @user.enable
    assert_equal users(:administrator_second_user).failed_attempts,
      @user.failed_attempts
    assert_equal users(:administrator_second_user).last_access,
      @user.last_access
    assert_equal users(:administrator_second_user).logged_in, @user.logged_in
    assert_equal users(:administrator_second_user).resource_id,
      @user.resource_id
    assert_equal users(:administrator_second_user).manager_id,
      @user.manager_id
  end

  # Prueba la creación de un usuario
  test 'create' do
    assert_difference 'User.count' do
      role = Role.find(roles(:admin_role).id)

      role.inject_auth_privileges(Hash.new(true))

      @user = User.new(
        :name => 'New name',
        :last_name => 'New lastname',
        :language => 'es',
        :email => 'emailxx@emailxx.ccc',
        :function => 'New function',
        :user => 'new_user',
        :enable => true,
        :failed_attempts => 0,
        :logged_in => false,
        :resource_id => resources(:auditor_resource).id,
        :parent => users(:administrator_user),
        :organization_roles_attributes => {
          :new_1 => {
            :organization => organizations(:default_organization),
            :role => role
          }
        }
      )

      assert @user.save, @user.errors.full_messages.join('; ')
      assert_equal 'New name', @user.name
      assert_not_nil @user.parent
    end
  end

  # Prueba de actualización de un usuario
  test 'update' do
    assert_no_difference 'User.count' do
      assert @user.update_attributes(
        :name => 'New name', :last_name => 'New last name'),
        @user.errors.full_messages.join('; ')
    end

    @user.reload
    assert_equal 'New name', @user.name
    assert_equal 'New last name', @user.last_name
  end

  # Prueba de eliminación de usuarios
  test 'destroy' do
    assert_difference('User.count', -1) { @user.destroy }
  end

  test 'destroy audited user with findings' do
    audited = User.find users(:audited_user).id

    assert_no_difference('User.count') { audited.destroy }

    assert_equal 1, audited.errors.size
    assert_equal I18n.t(:'user.will_be_orphan_findings'),
      audited.errors.full_messages.join

    audited.findings.delete audited.findings.all_for_reallocation

    assert_difference('User.count', -1) { audited.destroy }
  end

  test 'disable manager user' do
    user = User.find(users(:manager_user).id)
    reviews = user.reviews.select { |r| !r.has_final_review? }
    any_with_pending_findings = reviews.any? do |r|
      !user.findings.all_for_reallocation_with_review(r).empty?
    end
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert any_with_pending_findings
    assert user.enable?

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert_no_difference 'user.reviews.count' do
        assert !user.disable!
      end
    end

    assert user.enable?
    assert_equal 1, user.errors.size
    assert_equal I18n.t(:'user.will_be_orphan_findings'),
      user.errors.full_messages.first
  end

  test 'disable auditor user' do
    user = User.find(users(:first_time_user).id)
    new_user = User.find(users(:expired_user).id)
    reviews = user.reviews.select { |r| !r.has_final_review? }
    any_with_pending_findings = reviews.any? do |r|
      !user.findings.all_for_reallocation_with_review(r).empty?
    end

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert any_with_pending_findings
    assert user.enable?

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert_no_difference 'user.reviews.count' do
        assert !user.disable!
      end
    end

    assert user.enable?
    assert_equal 1, user.errors.size
    assert_equal I18n.t(:'user.will_be_orphan_findings'),
      user.errors.full_messages.first

    assert_difference 'user.reviews.count', -1 do
      user.errors.clear

      assert user.reassign_to(new_user, :with_findings => true,
        :with_reviews => true)

      assert user.disable!
    end

    assert !user.enable?
    assert user.errors.empty?, user.errors.full_messages.join('; ')
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @user.name = nil
    @user.last_name = nil
    @user.language = '   '
    @user.email = '  '
    @user.organization_roles.clear
    assert @user.invalid?
    assert_equal 6, @user.errors.count
    assert_equal error_message_from_model(@user, :name, :blank),
      @user.errors.on(:name)
    assert_equal error_message_from_model(@user, :last_name, :blank),
      @user.errors.on(:last_name)
    assert_equal error_message_from_model(@user, :language, :blank),
      @user.errors.on(:language)
    assert_equal error_message_from_model(@user, :email, :blank),
      @user.errors.on(:email)
    assert_equal error_message_from_model(@user, :manager_id, :invalid),
      @user.errors.on(:manager_id)
    assert_equal error_message_from_model(@user, :organization_roles, :blank),
      @user.errors.on(:organization_roles)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @user.name = '?nil'
    @user.last_name = '?123'
    @user.email = 'incorrect@format'
    assert @user.invalid?
    assert_equal 3, @user.errors.count
    assert_equal error_message_from_model(@user, :name, :invalid),
      @user.errors.on(:name)
    assert_equal error_message_from_model(@user, :last_name, :invalid),
      @user.errors.on(:last_name)
    assert_equal error_message_from_model(@user, :email, :invalid),
      @user.errors.on(:email)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @user.user = users(:bare_user).user
    @user.email = users(:bare_user).email
    @user.name = users(:bare_user).name
    @user.last_name = users(:bare_user).last_name
    assert @user.invalid?
    assert_equal 3, @user.errors.count
    assert_equal error_message_from_model(@user, :user, :taken),
      @user.errors.on(:user)
    assert_equal error_message_from_model(@user, :email, :taken),
      @user.errors.on(:email)
    assert_equal error_message_from_model(@user, :name, :taken),
      @user.errors.on(:name)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates confirmated attributes' do
    @user.password = 'admin124'
    @user.password_confirmation = 'admin125'
    assert @user.invalid?
    assert_equal 1, @user.errors.count
    assert_equal error_message_from_model(@user, :password, :confirmation),
      @user.errors.on(:password)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @user.user = 'abcd'
    assert @user.invalid?
    assert_equal 1, @user.errors.count
    assert_equal error_message_from_model(@user, :user, :too_short,
      :count => 5), @user.errors.on(:user)

    @user.user = 'abcd' * 10
    @user.name = 'abcde' * 21
    @user.last_name = 'abcde' * 21
    @user.email = "#{'abcde' * 21}@email.com"
    @user.language = 'abcde' * 3
    @user.password = 'aB1d_' * 26
    @user.function = 'abcde' * 52
    @user.salt = 'abcde' * 52
    @user.change_password_hash = 'abcde' * 52
    assert @user.invalid?
    assert_equal 9, @user.errors.count
    assert_equal error_message_from_model(@user, :user, :too_long,
      :count => 30), @user.errors.on(:user)
    assert_equal error_message_from_model(@user, :name, :too_long,
      :count => 100), @user.errors.on(:name)
    assert_equal error_message_from_model(@user, :last_name, :too_long,
      :count => 100), @user.errors.on(:last_name)
    assert_equal error_message_from_model(@user, :email, :too_long,
      :count => 100), @user.errors.on(:email)
    assert_equal error_message_from_model(@user, :language, :too_long,
      :count => 10), @user.errors.on(:language)
    assert_equal error_message_from_model(@user, :password, :too_long,
      :count => 128), @user.errors.on(:password)
    assert_equal error_message_from_model(@user, :function, :too_long,
      :count => 255), @user.errors.on(:function)
    assert_equal error_message_from_model(@user, :salt, :too_long,
      :count => 255), @user.errors.on(:salt)
    assert_equal error_message_from_model(@user, :change_password_hash,
      :too_long, :count => 255), @user.errors.on(:change_password_hash)
  end

  test 'validates parent is in the same organization' do
    user = User.find(users(:bare_user).id)
    bad_parent = User.find(users(:administrator_second_user).id)

    assert user.valid?
    user.parent = bad_parent
    assert user.invalid?
    assert_equal 1, user.errors.size
    assert_equal error_message_from_model(user, :manager_id, :invalid),
      user.errors.on(:manager_id)
  end

  test 'validates password changed too soon' do
    assert_difference 'OldPassword.count' do
      assert @user.update_attributes(
        {
          :password => "new_password_1230",
          :password_confirmation => "new_password_1230",
          :password_changed => Date.today
        }
      ), @user.errors.full_messages.join('; ')
    end

    assert_no_difference 'OldPassword.count' do
      assert !@user.update_attributes(
        {
          :password => "new_password_1232",
          :password_confirmation => "new_password_1232",
          :password_changed => Date.today
        }
      )
    end

    assert_equal 1, @user.errors.count
    assert_equal error_message_from_model(@user, :password,
      :too_soon,
      :count => get_test_parameter(:security_password_minimum_time).to_i),
      @user.errors.on(:password)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates already used password' do
    password_count = get_test_parameter(:security_password_count).to_i

    assert password_count > 0

    assert_difference 'OldPassword.count' do
      assert @user.update_attributes(
        {
          :password => "new_password_1230",
          :password_confirmation => "new_password_1230"
        }
      ), @user.errors.full_messages.join('; ')
    end

    (1..password_count).each do |c|
      assert_difference 'OldPassword.count' do
        assert @user.update_attributes(
          {
            :password => "new_password_123#{c}",
            :password_confirmation => "new_password_123#{c}"
          }
        )
      end

      (1...c).each do |c2|
        assert_no_difference 'OldPassword.count' do
          @user.attributes = {
            :password => "new_password_123#{c2}",
            :password_confirmation => "new_password_123#{c2}"
          }

          assert @user.invalid?
          assert_equal 1, @user.errors.count
          assert_equal error_message_from_model(@user, :password, :already_used),
            @user.errors.on(:password)
        end
      end
    end

    assert_difference 'OldPassword.count' do
      assert @user.update_attributes(
        {
          :password => "new_password_1230",
          :password_confirmation => "new_password_1230"
        }
      )
    end
  end

  test 'versiones to string methods' do
    old_name_with_function = @user.full_name_with_function

    assert_no_match /New function/, old_name_with_function
    assert @user.update_attributes(:function => 'New function')

    new_name_with_function = @user.full_name_with_function
    assert_match /New function/, new_name_with_function

    name_from_a_minute_ago = @user.full_name_with_function(1.minute.ago)
    assert_no_match /New function/, name_from_a_minute_ago
    assert_equal old_name_with_function, name_from_a_minute_ago
  end

  test 'blank password' do
    assert_not_nil @user.password

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size' do
      @user.blank_password!(organizations(:default_organization))
    end

    assert_nil @user.password
  end

  test 'privileges' do
    user = User.find users(:administrator_user).id
    privileges = user.privileges(organizations(:default_organization))

    assert !privileges.blank?

    privileges.each do |module_name, privilege|
      assert APP_MODULES.include?(module_name)
      assert privilege.kind_of?(Hash)
      assert privilege.has_key?(:approval)
      assert privilege.has_key?(:erase)
      assert privilege.has_key?(:modify)
      assert privilege.has_key?(:read)
    end
  end

  test 'change user role from auditor to audited' do
    auditor_user = User.find(users(:auditor_user).id)

    assert !auditor_user.findings.all_for_reallocation.empty?

    auditor_user.organization_roles.each {|o_r| o_r.role = roles(:audited_role)}

    assert !auditor_user.save
    assert_equal 1, auditor_user.errors.size
    assert_equal error_message_from_model(auditor_user, :organization_roles,
      :invalid), auditor_user.errors.on(:organization_roles)

    auditor_user.reload

    assert auditor_user.reassign_to(User.find(users(:bare_user).id),
      {:with_reviews => true, :with_findings => true})

    assert auditor_user.reload.findings.all_for_reallocation.empty?
    auditor_user.organization_roles.each {|o_r| o_r.role = roles(:audited_role)}

    assert auditor_user.save
  end

  test 'release for all pending fingings' do
    auditor_user = User.find users(:auditor_user).id

    assert !auditor_user.findings.all_for_reallocation.empty?
    assert !auditor_user.reviews.list_without_final_review(
      organizations(:default_organization)).empty?

    assert_nothing_raised do
      assert auditor_user.release_for_all_pending_findings(
        :with_reviews => true, :with_findings => true)
    end

    assert auditor_user.findings(true).all_for_reallocation.empty?
    assert auditor_user.reviews(true).list_without_final_review(
      organizations(:default_organization)).empty?
  end

  test 'try to release all pending findings for a unique audited' do
    audited_user = User.find users(:audited_user).id
    old_findings_count = audited_user.findings.all_for_reallocation.count
    old_reviews_count = audited_user.reviews.list_without_final_review(
      organizations(:default_organization)).count

    assert !audited_user.findings.all_for_reallocation.empty?
    assert !audited_user.reviews.list_without_final_review(
      organizations(:default_organization)).empty?

    assert_nothing_raised do
      assert !audited_user.release_for_all_pending_findings(
        :with_reviews => true, :with_findings => true)
    end

    assert !audited_user.findings(true).all_for_reallocation.empty?
    assert !audited_user.reviews(true).list_without_final_review(
      organizations(:default_organization)).empty?
    assert_equal old_findings_count,
      audited_user.findings.all_for_reallocation.count
    assert_equal old_reviews_count, audited_user.reviews.
      list_without_final_review(organizations(:default_organization)).count
    assert_equal 1, audited_user.errors.size
    assert_equal I18n.t(:'user.user_release_failed'),
      audited_user.errors.full_messages.first
  end

  test 'send welcome email' do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference "ActionMailer::Base.deliveries.size" do
      @user.send_notification_email = true
      @user.send_welcome_email
    end
  end

  test 'must change the password and days for password expiration' do
    assert_nil @user.days_for_password_expiration
    @user.password_changed = get_test_parameter(
      :security_password_expire_time).to_i.next.days.ago

    assert @user.must_change_the_password?
    assert @user.days_for_password_expiration < 0
  end

  test 'user findings reassignment' do
    old_user = User.find users(:audited_user).id
    user = User.find users(:audited_second_user).id
    original_finding_ids = old_user.findings.all_for_reallocation.
      map { |f| f.id }.sort

    assert !old_user.findings.all_for_reallocation.blank?
    assert user.findings.all_for_reallocation.blank?

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size', 2 do
      assert_difference 'Notification.count' do
        old_user.reassign_to(user, :with_findings => true)
      end
    end

    assert old_user.reload.findings.all_for_reallocation.blank?
    assert !user.findings.all_for_reallocation.blank?
    assert_equal original_finding_ids,
      user.findings.all_for_reallocation.map { |f| f.id }.sort
  end

  test 'user reviews reassignment' do
    old_user = User.find users(:audited_user).id
    user = User.find users(:audited_second_user).id
    reviews_to_reassign = old_user.reviews.reject { |r| r.has_final_review? }
    notifications = reviews_to_reassign.size

    assert !reviews_to_reassign.empty?
    assert !reviews_to_reassign.all? {|r| r.users.include?(user) }

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size', notifications * 2 do
      assert_difference 'Notification.count', notifications do
        old_user.reassign_to(user, :with_reviews => true)
      end
    end

    assert old_user.reload.reviews.reject { |r| r.has_final_review? }.empty?
    assert reviews_to_reassign.all? {|r| r.users.include?(user) }
  end

  test 'notify finding changes function' do
    GlobalModelConfig.current_organization_id = nil
    user = User.find users(:administrator_user).id
    # Sólo funciona si no es un fin de semana
    assert ![0, 6].include?(Date.today.wday)
    assert !user.findings.for_notification.empty?
    assert !Finding.for_notification.empty?

    assert_difference 'Finding.for_notification.size' do
      finding = user.findings.detect do |f|
        f.state != Finding::STATUS[:notify] && !f.is_in_a_final_review?
      end

      new_finding = finding.clone
      new_finding.state = Finding::STATUS[:notify]
      new_finding.review_code = "O#{rand(999999999999999)}"
      new_finding.user_ids = finding.user_ids
      
      assert new_finding.save, new_finding.errors.full_messages.join('; ')
    end

    review_codes_by_user = {}

    User.all_with_findings_for_notification.each do |user|
      review_codes_by_user[user] =
        user.findings.for_notification.map(&:review_code)
    end

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size', 6 do
      User.notify_new_findings
    end

    review_codes_by_user.each do |user, review_codes|
      ActionMailer::Base.deliveries.each do |mail|
        if mail.to.include?(user.email)
          assert review_codes.all? { |r_c| mail.body.match(Regexp.new(r_c)) }
        end
      end
    end

    assert Finding.for_notification.empty?
  end
end