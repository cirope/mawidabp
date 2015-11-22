module Users::Params
  extend ActiveSupport::Concern

  private

    def user_params
      params.require(:user).permit(
        :user, :name, :last_name, :email, :language, :notes, :resource_id,
        :manager_id, :enable, :logged_in, :password, :password_confirmation,
        :hidden, :function, :send_notification_email, :confirmation_hash,
        :lock_version, child_ids: [],
        organization_roles_attributes: [:id, :organization_id, :role_id, :_destroy],
        related_user_relations_attributes: [:id, :related_user_id, :_destroy]
      )
    end
end
