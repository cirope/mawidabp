module Privileges::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :read, :boolean
    attribute :modify, :boolean
    attribute :erase, :boolean
    attribute :approval, :boolean
  end
end
