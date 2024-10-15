module Users::Mfa
  extend ActiveSupport::Concern

  included do
    acts_as_google_authenticated lookup_token: :mfa_secret, drift: 15
  end

  def require_mfa?
    organization_role = organization_roles.where(organization_id: Current.organization&.id).take

    organization_role&.require_mfa
  end

  def mfa_config_done!
    update_column :mfa_done, true
  end
end
