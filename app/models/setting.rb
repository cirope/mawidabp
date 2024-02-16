class Setting < ApplicationRecord
  include Auditable
  include Settings::Validations
  include Settings::Scopes

  attr_readonly :name

  belongs_to :organization

  def to_s
    description
  end
end
