# frozen_string_literal: true

module ControlObjectiveItems::ScoredBusinessUnitType
  extend ActiveSupport::Concern

  included do
    belongs_to :scored_business_unit_type, class_name: 'BusinessUnitType', optional: true
  end
end
