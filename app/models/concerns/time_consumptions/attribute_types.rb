module TimeConsumptions::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :limit, :float
  end
end
