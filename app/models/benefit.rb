class Benefit < ActiveRecord::Base
  include Auditable
  include Benefits::Scopes
  include Benefits::Validations

  belongs_to :organization

  def to_s
    name
  end
end
