class RiskCategory < ApplicationRecord
  include RiskCategories::Scopes
  include RiskCategories::Relations
  include RiskCategories::Validation

  def to_s
    name
  end
end
