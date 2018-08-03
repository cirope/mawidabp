module ReviewUserAssignments::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :include_signature, :boolean
    attribute :owner, :boolean
  end
end
