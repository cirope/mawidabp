module Users::Update
  extend ActiveSupport::Concern

  module ClassMethods
    def update_user user: nil, data: nil, roles: nil
      new_roles = roles.map do |r|
        unless user.organization_roles.detect { |o_r| o_r.role_id == r.id }
          { organization_id: r.organization_id, role_id: r.id }
        end
      end

      removed_roles = user.organization_roles.map do |o_r|
        if roles.map(&:id).exclude? o_r.role_id
          { id: o_r.id, _destroy: '1' } if o_r.organization_id == Current.organization&.id
        end
      end

      data[:organization_roles_attributes] = new_roles.compact + removed_roles.compact

      if roles.blank? && removed_roles.compact.blank?
        false
      else
        user.update data
      end
    end
  end
end
