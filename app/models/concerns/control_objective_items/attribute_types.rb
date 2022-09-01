module ControlObjectiveItems::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :audit_date, :date
    attribute :finished, :boolean
    attribute :exclude_from_score, :boolean
  end
end
