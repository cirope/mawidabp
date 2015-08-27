module BestPractices::Scopes
  extend ActiveSupport::Concern

  module ClassMethods
    def list_conditions
      conditions       = [
        "#{table_name}.#{qcn 'shared'} = :false AND #{table_name}.#{qcn 'organization_id'} = :organization_id",
        "#{table_name}.#{qcn 'shared'} = :true  AND #{table_name}.#{qcn 'group_id'} = :group_id"
      ].map { |c| "(#{c})" }.join(' OR ')

      [
        conditions, {
          false:           false,
          true:            true,
          organization_id: Organization.current_id,
          group_id:        Group.current_id
        }
      ]
    end

    def list
      where(*list_conditions).order(name: :asc)
    end
  end
end
