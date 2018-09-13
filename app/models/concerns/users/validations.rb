module Users::Validations
  extend ActiveSupport::Concern

  included do
    validates :user, uniqueness: { case_sensitive: false }, unless: :ldap?
    validates :user, length: { in: 3..30 }, pdf_encoding: true
    validates :name, :last_name, :email, presence: true, length: { maximum: 100 },
      pdf_encoding: true
    validates :password, length: { maximum: 128 }, allow_nil: true, allow_blank: true
    validates :function, :salt, :change_password_hash, length: { maximum: 255 },
      allow_nil: true, allow_blank: true
    validates :password, confirmation: true, unless: :is_encrypted?
    validates :language, length: { maximum: 10 }, presence: true
    validates :email, format: { with: EMAIL_REGEXP }, allow_nil: true, allow_blank: true
    validate :validate_manager
    validate :validate_roles, on: :create
    validate :validate_password
    validate :validate_email_group_uniqueness
  end

  private

    def ldap?
      LdapConfig.exists? organization_id: Current.organization&.id
    end

    def validate_manager
      if parent
        if children.include?(parent) || !share_organizations_with_his_manager?
          errors.add :manager_id, :invalid
        end
      end
    end

    def validate_roles
      if organization_roles.reject(&:marked_for_destruction?).blank?
        errors.add :organization_roles, :blank unless group_admin
      end
    end

    def validate_password
      old_user = User.find_by id: id

      errors.add :password, :invalid if password && password !~ password_regex
      errors.add :password, :too_short, count: password_min_length if has_invalid_password_length?

      if old_user
        errors.add :password, :already_used if repeat_password_from? old_user
        errors.add :password, :too_soon, count: password_min_time if not_in_acceptable_password_change_time?
      end
    end

    def validate_email_group_uniqueness
      if will_save_change_to_email?
        email_column = "#{self.class.quoted_table_name}.#{self.class.qcn 'email'}"
        # Getting group this way only to work also on new records
        group = organization_roles.take&.organization&.group
        has_users_with_same_email = group &&
          group.
          users.
          where.not(id: id).
          where("LOWER(#{email_column}) = ?", email.downcase).any?

        errors.add :email, :taken if has_users_with_same_email
      end
    end

    def share_organizations_with_his_manager?
      organization_roles.any? do |o_r|
        parent.organizations.find_by id: o_r.organization_id
      end
    end

    def password_min_length
      @_pml ||= get_parameter_for_now(:password_minimum_length).to_i
    end

    def password_min_time
      @_pmt ||= get_parameter_for_now(:password_minimum_time).to_i
    end

    def password_regex
      @_pc ||= Regexp.new get_parameter_for_now(:password_constraint)
    end

    def repeat_password_from? old_user
      digested_password = User.digest(password, old_user.salt) if password

      if password && old_user.password != digested_password
        last_passwords.any? { |p| p.password == digested_password }
      end
    end

    def has_invalid_password_length?
      password_min_length != 0 && password && password.length < password_min_length
    end

    def not_in_acceptable_password_change_time?
      password_min_time != 0 &&
        password != password_was &&
        password_changed_was > password_min_time.days.ago.to_date &&
        !first_login?
    end
end
