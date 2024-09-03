module RiskControlObjectives::Relations
  extend ActiveSupport::Concern

  included do
    belongs_to :risk
    belongs_to :control_objective
  end
end
