module NewsModule::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :shared, :boolean
  end
end
