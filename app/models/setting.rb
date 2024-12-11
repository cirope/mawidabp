class Setting < ApplicationRecord
  include Auditable
  include Parameters::Risk
  include Parameters::Priority
  include Parameters::Relevance
  include Parameters::Qualification
  include Settings::Validations
  include Settings::Scopes

  attr_readonly :name

  belongs_to :organization

  def to_s
    description
  end
end
