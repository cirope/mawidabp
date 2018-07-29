module Organizations::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :corporate, :boolean
  end
end
