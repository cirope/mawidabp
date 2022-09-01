module BestPractices::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :obsolete, :boolean
    attribute :shared, :boolean
  end
end
