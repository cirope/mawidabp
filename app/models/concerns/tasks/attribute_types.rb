module Tasks::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :due_on, :date
  end
end
