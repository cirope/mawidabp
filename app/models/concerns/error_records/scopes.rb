module ErrorRecords::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list,          -> { where organization_id: Current.organization&.id }
    scope :default_order, -> { reorder created_at: :desc }
  end
end
