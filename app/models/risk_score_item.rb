class RiskScoreItem < ApplicationRecord
  include Auditable
  include RiskScoreItems::Relations
  include RiskScoreItems::Scopes
  include RiskScoreItems::Validations

  def to_s
    name
  end
end
