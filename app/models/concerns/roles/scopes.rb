module Roles::Scopes
  extend ActiveSupport::Concern

  module ClassMethods
    def list
      list_by_organization Current.organization&.id
    end

    def list_by_organization organization_id
      where(organization_id: organization_id).order(name: :asc)
    end

    def list_by_organization_and_group organization, group
      includes(:organization).
        where(
          "#{table_name}.organization_id" => organization.id,
          "#{Organization.table_name}.group_id" => group.id
        ).
        references(:organizations)
    end

    def list_with_corporate
      organization  = Current.organization
      corporate_ids = organization.group.organizations.corporate.pluck 'id'
      ids           = corporate_ids | [organization.id]

      where(organization_id: ids).order name: :asc
    end
  end
end
