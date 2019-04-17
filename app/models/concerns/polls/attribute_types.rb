module Polls::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :answered, :boolean
  end
end
