module Tags::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :shared, :boolean
    attribute :obsolete, :boolean
  end
end
