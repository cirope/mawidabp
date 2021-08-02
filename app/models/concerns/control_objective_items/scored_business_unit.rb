# frozen_string_literal: true

module ControlObjectiveItems::ScoredBusinessUnit
  extend ActiveSupport::Concern

  included do
    belongs_to :scored_business_unit, class_name: 'BusinessUnit', optional: true
  end
end
