require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users :administrator_second_user

    set_organization
  end

  test 'create' do
    assert_difference 'User.count' do
      role = roles :admin_role

      role.inject_auth_privileges Hash.new(true)

      user = User.create!(
        name: 'New name',
        last_name: 'New lastname',
        language: 'es',
        email: 'emailxx@emailxx.ccc',
        function: 'New function',
        user: 'new_user',
        enable: true,
        failed_attempts: 0,
        logged_in: false,
        notes: 'Some user notes',
        resource_id: resources(:auditor_resource).id,
        manager_id: users(:administrator_user).id,
        organization_roles_attributes: [
          {
            organization_id: organizations(:cirope).id,
            role_id: role.id
          }
        ]
      )

      assert_not_nil user.parent
    end
  end

  test 'update' do
    assert_no_difference 'User.count' do
      @user.update! name: 'Updated name'
    end

    @user.reload
    assert_equal 'Updated name', @user.name
  end

  test 'destroy' do
    assert_difference('User.count', -1) { @user.destroy }
  end

  test 'can not destroy user with findings' do
    user = users :audited_user

    assert_no_difference('User.count') { user.destroy }
    assert user.errors.full_messages.include?(I18n.t('user.will_be_orphan_findings'))
  end

  test 'can not disable manager user' do
    user = users :manager_user

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert_no_difference 'user.reviews.count' do
        assert !user.disable!
      end
    end

    assert user.enable?
    assert user.errors.full_messages.include?(I18n.t('user.will_be_orphan_findings'))
  end

  test 'disable auditor user' do
    user = users :first_time_user
    new_user = users :expired_user

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert_no_difference 'user.reviews.count' do
        assert !user.disable!
      end
    end

    assert user.enable?
    assert user.errors.full_messages.include?(I18n.t('user.will_be_orphan_findings'))

    user.errors.clear

    assert user.reassign_to(new_user, with_findings: true, with_reviews: true)
    assert user.reload.disable!

    assert !user.enable?
    assert user.errors.empty?
  end

  test 'validates blank attributes' do
    @user.name = nil
    @user.last_name = nil
    @user.language = '   '
    @user.email = '  '
    @user.organization_roles.clear

    assert @user.invalid?
    assert_error @user, :name, :blank
    assert_error @user, :last_name, :blank
    assert_error @user, :language, :blank
    assert_error @user, :email, :blank
    assert_error @user, :manager_id, :invalid
    assert_error @user, :organization_roles, :blank
  end

  test 'validates well formated attributes' do
    @user.email = 'incorrect@format'

    assert @user.invalid?
    assert_error @user, :email, :invalid
  end

  test 'validates duplicated attributes' do
    @user.user = users(:bare_user).user
    @user.email = users(:bare_user).email

    assert @user.invalid?
    assert_error @user, :user, :taken
    assert_error @user, :email, :taken
  end

  test 'validates confirmated attributes' do
    @user.password = 'admin124'
    @user.password_confirmation = 'admin125'

    assert @user.invalid?
    assert_error @user, :password_confirmation, :confirmation
  end

  test 'validates length of attributes' do
    @user.user = 'abcd'

    assert @user.invalid?
    assert_error @user, :user, :too_short, count: 5

    @user.user = 'abcd' * 10
    @user.name = 'abcde' * 21
    @user.last_name = 'abcde' * 21
    @user.email = "#{'abcde' * 21}@email.com"
    @user.password = 'aB1d_' * 26
    @user.function = 'abcde' * 52
    @user.salt = 'abcde' * 52
    @user.change_password_hash = 'abcde' * 52

    assert @user.invalid?
    assert_error @user, :user, :too_long, count: 30
    assert_error @user, :name, :too_long, count: 100
    assert_error @user, :last_name, :too_long, count: 100
    assert_error @user, :email, :too_long, count: 100
    assert_error @user, :password, :too_long, count: 128
    assert_error @user, :function, :too_long, count: 255
    assert_error @user, :salt, :too_long, count: 255
    assert_error @user, :change_password_hash, :too_long, count: 255
  end

  test 'validates parent is in the same organization' do
    user = users :bare_user
    user.parent = users :administrator_second_user

    assert user.invalid?
    assert_error user, :manager_id, :invalid
  end

  test 'validates parent is not child' do
    user = users :bare_user
    user.child_ids  = [users(:first_time_user).id]
    user.manager_id = users(:first_time_user).id

    assert user.invalid?
    assert_error user, :manager_id, :invalid
  end

  test 'validates password changed too soon' do
    assert_difference 'OldPassword.count' do
      @user.update!(
        password: 'new_password_1230',
        password_confirmation: 'new_password_1230',
        password_changed: Date.today
      )
    end

    assert_no_difference 'OldPassword.count' do
      @user.update(
        password: 'new_password_1232',
        password_confirmation: 'new_password_1232',
        password_changed: Date.today
      )
    end

    assert_error @user, :password, :too_soon, count: get_test_parameter(:password_minimum_time).to_i
  end

  test 'validates already used password' do
    password_count = get_test_parameter(:password_count).to_i

    assert password_count > 0

    assert_difference 'OldPassword.count' do
      @user.update!(
        password: 'new_password_1230',
        password_confirmation: 'new_password_1230'
      )
    end

    (1..password_count).each do |c|
      assert_difference 'OldPassword.count' do
        @user.update!(
          password: "new_password_123#{c}",
          password_confirmation: "new_password_123#{c}"
        )
      end

      (1...c).each do |c2|
        assert_no_difference 'OldPassword.count' do
          @user.attributes = {
            password: "new_password_123#{c2}",
            password_confirmation: "new_password_123#{c2}"
          }

          assert @user.invalid?
          assert_error @user, :password, :already_used
        end
      end
    end

    assert_difference 'OldPassword.count' do
      @user.update!(
        password: 'new_password_1230',
        password_confirmation: 'new_password_1230'
      )
    end
  end

  test 'versions to string methods' do
    old_name_with_function = @user.full_name_with_function

    assert_no_match /New function/, old_name_with_function
    assert @user.update(function: 'New function')

    new_name_with_function = @user.full_name_with_function
    assert_match /New function/, new_name_with_function

    name_from_a_minute_ago = @user.reload.full_name_with_function(1.minute.ago)
    assert_no_match /New function/, name_from_a_minute_ago
    assert_equal old_name_with_function, name_from_a_minute_ago
  end

  test 'confirmation_hash' do
    @user.update! password_changed: 31.days.ago, change_password_hash: SecureRandom.urlsafe_base64
    assert_nil @user.confirmation_hash

    @user.update! password_changed: 2.days.ago
    assert_not_nil @user.confirmation_hash
  end

  test 'reset password' do
    assert_nil @user.change_password_hash

    assert_difference 'ActionMailer::Base.deliveries.size' do
      @user.reset_password! organizations(:cirope)
    end

    assert_not_nil @user.reload.change_password_hash
  end

  test 'privileges' do
    user = users :administrator_user
    privileges = user.privileges organizations(:cirope)

    assert privileges.present?

    privileges.each do |module_name, privilege|
      assert APP_MODULES.include?(module_name)
      assert privilege.has_key?(:approval)
      assert privilege.has_key?(:erase)
      assert privilege.has_key?(:modify)
      assert privilege.has_key?(:read)
    end
  end

  test 'change user role from auditor to audited' do
    auditor_user = users :auditor_user

    assert auditor_user.findings.all_for_reallocation.present?

    auditor_user.organization_roles.each { |o_r| o_r.role = roles(:audited_role) }

    assert !auditor_user.save
    assert_error auditor_user, :organization_roles, :invalid

    auditor_user.reload

    assert auditor_user.reassign_to(users(:bare_user), with_reviews: true, with_findings: true)
    assert auditor_user.reload.findings.all_for_reallocation.empty?

    auditor_user.organization_roles.each { |o_r| o_r.role = roles(:audited_role) }

    assert auditor_user.save
  end

  test 'release for all pending fingings' do
    auditor_user = users :auditor_user

    assert auditor_user.findings.all_for_reallocation.any?
    assert auditor_user.reviews.list_without_final_review.any?

    assert_nothing_raised do
      assert auditor_user.release_for_all_pending_findings(with_reviews: true, with_findings: true)
    end

    assert auditor_user.findings.reload.all_for_reallocation.empty?
    assert auditor_user.reviews.reload.list_without_final_review.empty?
  end

  test 'try to release all pending findings for a unique audited' do
    audited_user = users :audited_user
    old_findings_count = audited_user.findings.all_for_reallocation.count
    old_reviews_count = audited_user.reviews.list_without_final_review.count

    assert audited_user.findings.all_for_reallocation.any?
    assert audited_user.reviews.list_without_final_review.any?

    assert_nothing_raised do
      assert !audited_user.release_for_all_pending_findings(with_reviews: true, with_findings: true)
    end

    assert audited_user.findings.reload.all_for_reallocation.any?
    assert audited_user.reviews.reload.list_without_final_review.any?
    assert_equal old_findings_count, audited_user.findings.all_for_reallocation.count
    assert_equal old_reviews_count, audited_user.reviews.list_without_final_review.count
    assert audited_user.errors.full_messages.include?(I18n.t('user.user_release_failed'))
  end

  test 'send welcome email' do
    assert_difference 'ActionMailer::Base.deliveries.size' do
      @user.send_notification_email = true
      @user.send_welcome_email
    end
  end

  test 'must change the password and days for password expiration' do
    assert_nil @user.days_for_password_expiration
    @user.password_changed = get_test_parameter(:password_expire_time).to_i.next.days.ago

    assert @user.must_change_the_password?
    assert @user.days_for_password_expiration < 0
  end

  test 'user findings reassignment' do
    old_user = users :audited_user
    user = users :audited_second_user
    original_finding_ids = old_user.findings.all_for_reallocation.pluck('id').sort

    assert old_user.findings.all_for_reallocation.any?
    assert user.findings.all_for_reallocation.blank?

    assert_difference 'ActionMailer::Base.deliveries.size', 2 do
      assert_difference 'Notification.count' do
        old_user.reassign_to user, with_findings: true
      end
    end

    assert old_user.reload.findings.all_for_reallocation.blank?
    assert user.findings.all_for_reallocation.any?
    assert_equal original_finding_ids, user.findings.all_for_reallocation.pluck('id').sort
  end

  test 'user reviews reassignment' do
    old_user = users :audited_user
    user = users :audited_second_user
    reviews_to_reassign = old_user.reviews.reject &:has_final_review?
    notifications = reviews_to_reassign.size

    assert reviews_to_reassign.any? { |r| r.users.exclude?(user) }

    assert_difference 'ActionMailer::Base.deliveries.size', notifications do
      assert_difference 'Notification.count' do
         old_user.reassign_to user, with_reviews: true
      end
    end

    assert old_user.reload.reviews.reject(&:has_final_review?).empty?
    assert reviews_to_reassign.all? { |r| r.reload.users.include?(user) }
  end

  test 'notify finding changes function' do
    Organization.current_id = nil
    user = users :administrator_user

    assert user.findings.for_notification.any?

    assert_difference 'Finding.for_notification.size' do
      finding = findings :bcra_A4609_data_proccessing_impact_analisys_editable_weakness

      new_finding = finding.dup
      new_finding.state = Finding::STATUS[:notify]
      new_finding.review_code = "O1#{rand(999999999999999)}"
      new_finding.finding_user_assignments.build(
        finding.finding_user_assignments.map do |fua|
          fua.dup.attributes.merge('finding_id' => nil)
        end
      )

      assert new_finding.save
    end

    review_codes_by_user = {}

    User.all_with_findings_for_notification.each do |user|
      review_codes_by_user[user] = user.findings.for_notification.pluck 'review_code'
    end

    ActionMailer::Base.deliveries.clear

    assert_difference 'ActionMailer::Base.deliveries.size', 6 do
      User.notify_new_findings
    end

    review_codes_by_user.each do |user, review_codes|
      ActionMailer::Base.deliveries.each do |mail|
        if mail.to.include?(user.email)
          assert review_codes.all? { |rc| mail.body.match /#{rc}/ }
        end
      end
    end

    assert Finding.for_notification.empty?
  end
end
