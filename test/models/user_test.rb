# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @user = users :administrator_second

    ActionMailer::Base.deliveries.clear

    set_organization
  end

  teardown do
    Current.organization = nil
    Current.user         = nil
  end

  test 'create' do
    assert_difference %w(User.count BusinessUnitTypeUser.count) do
      role = roles :admin_role

      role.inject_auth_privileges Hash.new(true)

      user = User.create!(
        name: 'New name',
        last_name: 'New lastname',
        language: 'es',
        email: 'emailxx@emailxx.ccc',
        function: 'New function',
        office: 'New office',
        user: 'new_user',
        enable: true,
        failed_attempts: 0,
        logged_in: false,
        notes: 'Some user notes',
        manager_id: users(:administrator).id,
        organization_roles_attributes: [
          {
            organization_id: organizations(:cirope).id,
            role_id: role.id
          }
        ],
        business_unit_type_users_attributes: [
          {
            business_unit_type_id: business_unit_types(:cycle).id
          }
        ]
      )

      assert_not_nil user.parent
    end
  end

  test 'new user should fail with duplicated email' do
    role = roles :admin_role

    role.inject_auth_privileges Hash.new(true)

    user = User.new(
      name: 'New name',
      last_name: 'New lastname',
      language: 'es',
      email: users(:bare).email,
      function: 'New function',
      office: 'New office',
      user: 'new_user',
      enable: true,
      failed_attempts: 0,
      logged_in: false,
      notes: 'Some user notes',
      organization_roles_attributes: [
        {
          organization_id: organizations(:cirope).id,
          role_id: role.id
        }
      ]
    )

    assert user.invalid?
    assert_error user, :email, :taken
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
    user = users :audited

    assert_no_difference('User.count') { user.destroy }
    assert user.errors.full_messages.include?(I18n.t('user.will_be_orphan_findings'))
  end

  test 'can not disable manager user' do
    user = users :manager

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert_no_difference 'user.reviews.count' do
        assert !user.disable
      end
    end

    assert user.enable?
    assert user.errors.full_messages.include?(I18n.t('user.will_be_orphan_findings'))
  end

  test 'disable auditor user' do
    user = users :first_time
    new_user = users :expired

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert_no_difference 'user.reviews.count' do
        assert !user.disable
      end
    end

    assert user.enable?
    assert user.errors.full_messages.include?(I18n.t('user.will_be_orphan_findings'))

    user.errors.clear

    assert user.reassign_to(new_user, with_findings: true, with_reviews: true)
    assert user.reload.disable

    assert !user.enable?
    assert user.errors.empty?
  end

  test 'validates blank attributes' do
    @user.name = nil
    @user.last_name = nil
    @user.language = '   '
    @user.email = '  '

    assert @user.invalid?
    assert_error @user, :name, :blank
    assert_error @user, :last_name, :blank
    assert_error @user, :language, :blank
    assert_error @user, :email, :blank
  end

  test 'validates well formated attributes' do
    @user.email = 'incorrect@format'

    assert @user.invalid?
    assert_error @user, :email, :invalid
  end

  test 'validates duplicated attributes' do
    @user.user = users(:administrator).user
    @user.email = users(:administrator).email

    assert @user.invalid?
    assert_error @user, :user, :taken
    assert_error @user, :email, :taken
  end

  test 'skip duplicated attributes on different groups' do
    @user.email = users(:bare).email

    assert @user.valid?
  end

  test 'disable uniqueness username validation' do
    o                    = organizations(:google)
    Current.organization = o

    o.settings.find_by(name: 'uniqueness_username_validation').update! value: '0'

    @user.user = users(:bare).user

    assert @user.valid?
  end

  test 'validates confirmated attributes' do
    @user.password = 'admin124'
    @user.password_confirmation = 'admin125'

    assert @user.invalid?
    assert_error @user, :password_confirmation, :confirmation
  end

  test 'validates length of attributes' do
    @user.user = 'ab'

    assert @user.invalid?
    assert_error @user, :user, :too_short, count: 3

    @user.user = 'abcde' * 52
    @user.name = 'abcde' * 21
    @user.last_name = 'abcde' * 21
    @user.email = "#{'abcde' * 52}@email.com"
    @user.password = 'aB1d_' * 26
    @user.function = 'abcde' * 52
    @user.office = 'abcde' * 52
    @user.organizational_unit = 'abcde' * 52
    @user.salt = 'abcde' * 52
    @user.change_password_hash = 'abcde' * 52

    assert @user.invalid?
    assert_error @user, :user, :too_long, count: 255
    assert_error @user, :name, :too_long, count: 100
    assert_error @user, :last_name, :too_long, count: 100
    assert_error @user, :email, :too_long, count: 255
    assert_error @user, :password, :too_long, count: 128
    assert_error @user, :function, :too_long, count: 255
    assert_error @user, :office, :too_long, count: 255
    assert_error @user, :organizational_unit, :too_long, count: 255
    assert_error @user, :salt, :too_long, count: 255
    assert_error @user, :change_password_hash, :too_long, count: 255
  end

  test 'validates parent is in the same organization' do
    user = users :bare
    user.parent = users :administrator_second

    assert user.invalid?
    assert_error user, :manager_id, :invalid
  end

  test 'validates parent is not child' do
    user = users :bare
    user.child_ids  = [users(:first_time).id]
    user.manager_id = users(:first_time).id

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

    assert_enqueued_emails 1 do
      @user.reset_password organizations(:cirope)
    end

    assert_not_nil @user.reload.change_password_hash
  end

  test 'restrict reset password for 10 minutes' do
    assert_nil @user.change_password_hash

    assert_enqueued_emails 1 do
      @user.reset_password organizations(:cirope)
    end

    assert_not_nil @user.reload.change_password_hash

    assert_nil @user.reset_password organizations(:cirope)

    @user.hash_changed = Time.zone.now - 11.minutes

     assert_enqueued_emails 1 do
       @user.reset_password organizations(:cirope)
     end
  end

  test 'privileges' do
    user = users :administrator
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

  test 'user role needed at creation ' do
    user = User.create(
      name: 'New name',
      last_name: 'New lastname',
      language: 'es',
      email: 'emailxx@emailxx.ccc',
      function: 'New function',
      office: 'New office',
      user: 'new_user',
      enable: true,
      failed_attempts: 0,
      logged_in: false,
      notes: 'Some user notes',
      manager_id: users(:administrator).id,
      organization_roles_attributes: []
    )

    assert_error user, :organization_roles, :blank
    assert_error user, :manager_id, :invalid
  end

  test 'change user role from auditor to audited' do
    auditor = users :auditor

    assert auditor.findings.all_for_reallocation.present?

    auditor.organization_roles.each { |o_r| o_r.role = roles(:audited_role) }

    assert !auditor.save
    assert_error auditor, :organization_roles, :invalid

    auditor.reload

    assert auditor.reassign_to(users(:bare), with_reviews: true, with_findings: true)
    assert auditor.reload.findings.all_for_reallocation.empty?

    auditor.organization_roles.each { |o_r| o_r.role = roles(:audited_role) }

    assert auditor.save
  end

  test 'remove user roles' do
    roles_attr = @user.organization_roles.map do |o_r|
      { id: o_r.id, _destroy: '1' }
    end

    assert @user.update(organization_roles_attributes: roles_attr)
    assert_empty @user.organization_roles.reload
  end

  test 'release for all pending fingings' do
    Current.organization = organizations :cirope
    Current.user         = users :auditor
    auditor              = Current.user

    assert auditor.findings.all_for_reallocation.any?
    assert auditor.reviews.list_without_final_review.any?

    assert_nothing_raised do
      assert auditor.release_pendings(with_reviews: true, with_findings: true)
    end

    assert auditor.findings.reload.all_for_reallocation.empty?
    assert auditor.reviews.reload.list_without_final_review.empty?
  end

  test 'try to release all pending findings for a unique audited' do
    Current.organization = organizations :cirope
    Current.user         = users :audited
    audited              = Current.user

    old_findings_count = audited.findings.all_for_reallocation.count
    old_reviews_count = audited.reviews.list_without_final_review.count

    assert audited.findings.all_for_reallocation.any?
    assert audited.reviews.list_without_final_review.any?

    assert_nothing_raised do
      assert !audited.release_pendings(with_reviews: true, with_findings: true)
    end

    assert audited.findings.reload.all_for_reallocation.any?
    assert audited.reviews.reload.list_without_final_review.any?
    assert_equal old_findings_count, audited.findings.all_for_reallocation.count
    assert_equal old_reviews_count, audited.reviews.list_without_final_review.count
    assert audited.errors.full_messages.include?(I18n.t('user.user_release_failed'))
  end

  test 'send welcome email' do
    assert_enqueued_emails 1 do
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
    old_user = users :audited
    user = users :audited_second
    original_finding_ids = old_user.findings.all_for_reallocation.pluck('id').sort

    assert old_user.findings.all_for_reallocation.any?
    assert user.findings.all_for_reallocation.blank?

    assert_enqueued_emails 2 do
      assert_difference 'Notification.count' do
        old_user.reassign_to user, with_findings: true
      end
    end

    assert old_user.reload.findings.all_for_reallocation.blank?
    assert user.findings.all_for_reallocation.any?
    assert_equal original_finding_ids, user.findings.all_for_reallocation.pluck('id').sort
  end

  test 'user reviews reassignment' do
    old_user = users :audited
    user = users :audited_second
    reviews_to_reassign = old_user.reviews.reject &:has_final_review?

    assert reviews_to_reassign.any? { |r| r.users.exclude?(user) }

    # One email each user...
    assert_enqueued_emails 2 do
      assert_difference 'Notification.count' do
         old_user.reassign_to user, with_reviews: true
      end
    end

    assert old_user.reload.reviews.reject(&:has_final_review?).empty?
    assert reviews_to_reassign.all? { |r| r.reload.users.include?(user) }
  end

  test 'reassign to none' do
    old_user = users :audited

    old_user.reassign_to nil, with_reviews: true

    assert old_user.errors.size > 0
  end

  test 'review assignment options' do
    Current.organization = organizations(:google)

    options = @user.review_assignment_options

    assert_equal 2, options.size
    assert options[:audited]
    assert options[:viewer]

    user    = users :supervisor
    options = user.review_assignment_options

    if Current.conclusion_pdf_format == 'gal'
      assert_equal 1, options.size
      assert options[:supervisor]
    else
      assert_equal 2, options.size
      assert options[:supervisor]
      assert options[:responsible]
    end
  end

  test 'notify finding changes function' do
    skip if USE_SCOPE_CYCLE

    Current.organization = nil
    user = users :administrator

    assert user.findings.for_notification.any?

    assert_difference 'Finding.for_notification.size' do
      finding = findings :unconfirmed_weakness

      new_finding = finding.dup
      new_finding.state = Finding::STATUS[:notify]
      new_finding.review_code = "O1#{rand(999999999999999)}"
      new_finding.finding_user_assignments.build(
        finding.finding_user_assignments.map do |fua|
          fua.dup.attributes.merge('finding_id' => nil)
        end
      )
      new_finding.taggings.build(
        finding.taggings.map do |t|
          t.dup.attributes.merge('id' => nil, 'taggable_id' => nil)
        end
      )

      assert new_finding.save
    end

    review_codes_by_user = {}

    User.all_with_findings_for_notification.each do |user|
      review_codes_by_user[user] = user.findings.for_notification.pluck 'review_code'
    end

    enqueued_emails = CHECK_FINDING_EMAIL_REPLIES ? 12 : 6

    assert_enqueued_emails enqueued_emails do
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

  test 'notify conclusion final review close date warning' do
    Current.user = users :supervisor

    ConclusionFinalReview.list.new(
      review_id: reviews(:review_approved_with_conclusion).id,
      issue_date: Date.today,
      close_date: CONCLUSION_FINAL_REVIEW_EXPIRE_DAYS.business_days.from_now.to_date,
      applied_procedures: 'New applied procedures',
      conclusion: CONCLUSION_OPTIONS.first,
      recipients: 'John Doe',
      sectors: 'Area 51',
      evolution: EVOLUTION_OPTIONS.second,
      evolution_justification: 'Ok',
      main_weaknesses_text: 'Some main weakness X',
      corrective_actions: 'You should do it this way',
      :reference => 'Some reference',
      :observations => 'Some observations',
      :scope => 'Some scope',
      affects_compliance: false
    ).save!

    Current.organization = nil

    users = User.all_with_conclusion_final_reviews_for_notification
    assert users.any?

    assert_enqueued_emails users.count do
      User.notify_auditors_about_close_date
    end
  end

  test 'auditor users limit reached' do
    group = groups :second_group

    group.update_columns licensed: true
    group.license.update_columns auditors_limit: 4

    set_organization organizations :alphabet

    assert_equal 4, group.users.can_act_as(:auditor).count

    role_id = Current.organization.roles.find_by(
      role_type: Role::TYPES[:auditor]
    ).id

    assert_no_difference 'User.count' do
      user = User.create(
        name:                          'New name',
        last_name:                     'New lastname',
        language:                      'es',
        email:                         'emailxx@emailxx.ccc',
        user:                          'new_user',
        enable:                        true,
        organization_roles_attributes: [
          {
            organization_id: Current.organization.id,
            role_id:         role_id
          }
        ]
      )

      assert user.new_record?
      assert_error user, :base, :auditors_limit_reached
    end
  end

  test 'not auditor users can be created with license limit' do
    group = groups :second_group

    group.update_columns licensed: true
    group.license.update_columns auditors_limit: 4

    set_organization organizations :alphabet

    assert_equal 4, group.users.can_act_as(:auditor).count

    role_id = Current.organization.roles.find_by(
      role_type: Role::TYPES[:admin]
    ).id

    assert_difference 'User.count' do
      User.create(
        name:                          'New name',
        last_name:                     'New lastname',
        language:                      'es',
        email:                         'emailxx@emailxx.ccc',
        user:                          'new_user',
        enable:                        true,
        organization_roles_attributes: [
          {
            organization_id: Current.organization.id,
            role_id:         role_id
          }
        ]
      )
    end
  end

  test 'notify new admin user on create' do
    skip unless NOTIFY_NEW_ADMIN

    set_organization

    organization = organizations :cirope
    email        = 'emailxx@emailxx.ccc'

    assert_enqueued_emails 1 do
      assert_difference 'User.count' do
        User.create!(
          name:                          'New name',
          last_name:                     'New lastname',
          language:                      'es',
          email:                         email,
          function:                      'New function',
          office:                        'New office',
          user:                          'new_user',
          enable:                        true,
          failed_attempts:               0,
          logged_in:                     false,
          notes:                         'Some user notes',
          manager_id:                    users(:administrator).id,
          organization_roles_attributes: [
            {
              organization_id: organization.id,
              role_id:         roles(:admin_role).id
            }
          ]
        )
      end
    end
  end

  test 'notify new admin user on update' do
    skip unless NOTIFY_NEW_ADMIN

    set_organization

    organization = organizations :cirope
    user         = users :audited

    user.organization_roles.each &:mark_for_destruction
    user.organization_roles.build(
      organization_id: organization.id,
      role_id:         roles(:admin_role).id
    )

    assert_enqueued_emails 1 do
      user.save!
    end
  end

  test 'import' do
    Current.organization = organizations(:google)
    organization         = Current.organization

    skip unless EXTRA_USERS_INFO.has_key? organization.prefix

    assert_difference 'User.count', 2 do
      User.import organization, 'admin', 'admin123'
    end

    one_user_file = User.find_by email: 'juan127@cirope.com'
    two_user_file = User.find_by email: 'pedro127@cirope.com'

    assert_equal one_user_file.manager_id, two_user_file.id
    assert_equal one_user_file.roles.count, 2
  end

  test 'should return auditors' do
    expected = User.includes(organization_roles: :role).where(
      roles: {
        role_type: ::Role::TYPES[:auditor]
      }
    )

    assert_equal expected, User.auditors
  end

  test 'should can act as audited when is audited' do
    assert users(:audited).can_act_as_audited?
  end

  test 'should not can act as audited when is audited and auditor' do
    skip if USE_SCOPE_CYCLE

    user = users(:audited)
    user.organization_roles << OrganizationRole.new(organization: organizations(:cirope), role: roles(:auditor_role))

    refute user.can_act_as_audited?
  end

  test 'should not can act as audited when is audited and supervisor' do
    skip if USE_SCOPE_CYCLE

    user = users(:audited)
    user.organization_roles << OrganizationRole.new(organization: organizations(:cirope), role: roles(:supervisor_role))

    refute user.can_act_as_audited?
  end

  test 'should not can act as audited when is audited and manager' do
    skip if USE_SCOPE_CYCLE

    user = users(:audited)
    user.organization_roles << OrganizationRole.new(organization: organizations(:cirope), role: roles(:manager_role))

    refute user.can_act_as_audited?
  end

  test 'should can act as audited when is executive manager' do
    assert users(:plain_manager).can_act_as_audited?
  end

  test 'should not can act as audited when is executive manager and auditor' do
    skip if USE_SCOPE_CYCLE

    user = users(:plain_manager)
    user.organization_roles << OrganizationRole.new(organization: organizations(:cirope), role: roles(:auditor_role))

    refute user.can_act_as_audited?
  end

  test 'should not can act as audited when is executive manager and supervisor' do
    skip if USE_SCOPE_CYCLE

    user = users(:plain_manager)
    user.organization_roles << OrganizationRole.new(organization: organizations(:cirope), role: roles(:supervisor_role))

    refute user.can_act_as_audited?
  end

  test 'should not can act as audited when is executive manager and manager' do
    skip if USE_SCOPE_CYCLE

    user = users(:plain_manager)
    user.organization_roles << OrganizationRole.new(organization: organizations(:cirope), role: roles(:manager_role))

    refute user.can_act_as_audited?
  end

  test 'should can act as audited when is admin' do
    assert users(:administrator).can_act_as_audited?
  end

  test 'should not can act as audited when is admin and auditor' do
    skip if USE_SCOPE_CYCLE

    user = users(:administrator)
    user.organization_roles << OrganizationRole.new(organization: organizations(:cirope), role: roles(:auditor_role))

    refute user.can_act_as_audited?
  end

  test 'should not can act as audited when is admin and supervisor' do
    skip if USE_SCOPE_CYCLE

    user = users(:administrator)
    user.organization_roles << OrganizationRole.new(organization: organizations(:cirope), role: roles(:supervisor_role))

    refute user.can_act_as_audited?
  end

  test 'should not can act as audited when is admin and manager' do
    skip if USE_SCOPE_CYCLE

    user = users(:administrator)
    user.organization_roles << OrganizationRole.new(organization: organizations(:cirope), role: roles(:manager_role))

    refute user.can_act_as_audited?
  end

  test 'should not can act as audited when is auditor' do
    refute users(:bare).can_act_as_audited?
  end

  test 'should not can act as audited when is supervisor' do
    refute users(:supervisor).can_act_as_audited?
  end

  test 'should not can act as audited when is manager' do
    refute users(:manager).can_act_as_audited?
  end

  test 'should not can act as audited when is committee' do
    refute users(:committee).can_act_as_audited?
  end
end
