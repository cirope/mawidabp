class RiskRegistry < ApplicationRecord
  include Auditable
  include RiskRegistries::Defaults
  include RiskRegistries::Relations
  include RiskRegistries::Scopes
  include RiskRegistries::Search
  include RiskRegistries::Validation
  include ParameterSelector

  def to_s
    name
  end
end
