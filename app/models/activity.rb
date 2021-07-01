class Activity < ApplicationRecord
  include Auditable
  include Activities::DestroyValidation
  include Activities::Validation

  belongs_to :activity_group, inverse_of: :activities
  has_many :time_consumptions, as: :resource_on, dependent: :restrict_with_error

  def to_s
    name
  end
end
