module Users::Roles
  extend ActiveSupport::Concern

  included do
    attr_accessor :roles_changed

    before_validation :inject_auth_privileges_in_roles, :set_proper_parent
    before_update :check_roles_changes

    has_many :organizations, through: :organization_roles
    has_many :organization_roles, dependent: :destroy,
      after_add:    :mark_roles_as_changed,
      after_remove: :mark_roles_as_changed
    accepts_nested_attributes_for :organization_roles, allow_destroy: true,
      reject_if: :reject_organization_role?
  end

  def roles organization_id = nil
    ors = organization_roles.reject(&:marked_for_destruction?)
    group = Group.find Group.current_id if Group.current_id
    organization_ids = [organization_id] | (group ? group.organizations.corporate.pluck('id') : [])

    ors.select! { |o_r| organization_ids.include?(o_r.organization_id) } if organization_id

    ors.map(&:role).sort
  end

  def allowed_modules
    roles.each_with_object([]) do |role, allowed|
      role.allowed_modules.each do |m|
        allowed << c if role.has_privilege_for?(m) && allowed.exclude?(m)
      end
    end
  end

  def get_menu
    audited? ? APP_AUDITED_MENU_ITEMS : APP_AUDITOR_MENU_ITEMS
  end

  def get_type
    roles(Organization.current_id).max.try(:get_type)
  end

  def privileges organization
    roles(organization.id).each_with_object({}) do |role, privileges|
      role.privileges.each do |privilege|
        module_name = privilege.module
        privileges[module_name]            ||= HashWithIndifferentAccess.new
        privileges[module_name][:read]     ||= privilege.read?
        privileges[module_name][:modify]   ||= privilege.modify?
        privileges[module_name][:erase]    ||= privilege.erase?
        privileges[module_name][:approval] ||= privilege.approval?
      end
    end.with_indifferent_access
  end

  Role::TYPES.each do |type, value|
    define_method("#{type}?") do
      roles(Organization.current_id).any? { |role| role.role_type == value }
    end

    define_method("#{type}_on?") do |organization_id|
      roles(organization_id).any? { |role| role.role_type == value }
    end
  end

  def auditor?
    auditor_junior? || auditor_senior?
  end

  def auditor_on? organization_id
    auditor_junior_on?(organization_id) || auditor_senior_on?(organization_id)
  end

  def can_act_as_audited?
    audited? || executive_manager?
  end

  def can_act_as_audited_on? organization_id
    audited_on?(organization_id) || executive_manager_on?(organization_id)
  end

  private

    def inject_auth_privileges_in_roles
      roles.each { |r| r.inject_auth_privileges Hash.new(Hash.new(true)) }
    end

    def set_proper_parent
      organization_roles.each { |o_r| o_r.user = self }
    end

    def check_roles_changes
      if roles_has_changed? && user_act_as_changed? && has_pending_findings?
        organization_roles.reload
        errors.add :organization_roles, :invalid

        false
      end
    end

    def reject_organization_role? attributes
      attributes['organization_id'].blank? || attributes['role_id'].blank?
    end

    def roles_has_changed?
      roles_changed || organization_roles.any?(&:changed?)
    end

    def user_act_as_changed?
      old_user = User.find id

      (old_user.auditor? && can_act_as_audited?) || (old_user.can_act_as_audited? && auditor?)
    end

    def mark_roles_as_changed organization_role
      organization_role.user = self unless organization_role.frozen?

      self.roles_changed = true
    end
end
