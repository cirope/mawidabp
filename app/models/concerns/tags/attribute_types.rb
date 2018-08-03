module Tags::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :shared, :boolean
  end
end
