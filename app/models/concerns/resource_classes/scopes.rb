module ResourceClasses::Scopes
  extend ActiveSupport::Concern
  include ResourceClasses::ResourceTypes

  included do
    scope :list, -> { where organization_id: Organization.current_id }
    scope :human_resources, -> {
      list.where(resource_class_type: TYPES[:human]).order(name: :asc)
    }
    scope :material_resources, -> {
      list.where(resource_class_type: TYPES[:material]).order(name: :asc)
    }
  end
end
