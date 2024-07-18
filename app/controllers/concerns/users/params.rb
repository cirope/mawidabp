module Users::Params
  extend ActiveSupport::Concern

  private

    def user_params
      allowed_params = if can_perform?(:edit, :approval)
                         admin_user_params
                       else
                         editor_user_params
                       end

      params.require(:user).permit *allowed_params
    end

    def editor_user_params
      [
        :manager_id, :function, :office, :lock_version,
        child_ids: [],
        related_user_relations_attributes: [:id, :related_user_id, :notify, :_destroy],
        business_unit_type_users_attributes: [:id, :business_unit_type_id, :_destroy],
        taggings_attributes: [:id, :tag_id, :_destroy]
      ]
    end

    def admin_user_params
      [
        :user, :name, :last_name, :email, :language, :notes,
        :manager_id, :enable, :logged_in, :password, :password_confirmation,
        :hidden, :function, :office, :send_notification_email,
        :confirmation_hash, :lock_version,
        child_ids: [],
        organization_roles_attributes: [:id, :organization_id, :role_id, :sync_ldap, :_destroy],
        related_user_relations_attributes: [:id, :related_user_id, :notify, :_destroy],
        business_unit_type_users_attributes: [:id, :business_unit_type_id, :_destroy],
        taggings_attributes: [:id, :tag_id, :_destroy]
      ]
    end
end
