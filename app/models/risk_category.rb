class RiskCategory < ApplicationRecord
  include RiskCategories::Relations
  include RiskCategories::Scopes
  include RiskCategories::Validation

  def to_s
    name
  end
end
