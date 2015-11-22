class Benefit < ActiveRecord::Base
  include Auditable
  include Benefits::Scopes
  include Benefits::Validations

  belongs_to :organization
  has_many :achievements, dependent: :destroy

  def to_s
    name
  end
end
