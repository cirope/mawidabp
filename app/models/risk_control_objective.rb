class RiskControlObjective < ApplicationRecord
  include Auditable
  include RiskControlObjectives::Relations
  include RiskControlObjectives::Validation
end
