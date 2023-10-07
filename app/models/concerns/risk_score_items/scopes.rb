module RiskScoreItems::Scopes
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order name: :asc }
  end
end
