module RiskScoreItems::Scopes
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order value: :asc }
  end
end
