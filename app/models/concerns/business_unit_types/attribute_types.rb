module BusinessUnitTypes::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :external, :boolean
    attribute :require_tag, :boolean
    attribute :require_counts, :boolean
  end
end
