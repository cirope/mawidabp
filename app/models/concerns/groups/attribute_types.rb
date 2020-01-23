module Groups::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :licensed, :boolean
  end
end
