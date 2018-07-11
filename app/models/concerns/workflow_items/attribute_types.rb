module WorkflowItems::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :start, :date
    attribute :end, :date
  end
end
