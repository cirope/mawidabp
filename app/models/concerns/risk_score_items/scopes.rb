module RiskScoreItems::Scopes
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order value: :desc }
  end
end
