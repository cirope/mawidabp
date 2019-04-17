module ControlObjectives::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :obsolete, :boolean
  end
end
