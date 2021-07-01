class Activity < ApplicationRecord
  include Auditable
  include Activities::DestroyValidation
  include Activities::Validation

  belongs_to :activity_group, inverse_of: :activities
  has_many :time_consumptions, as: :resource, dependent: :restrict_with_error, inverse_of: :activity

  def to_s
    name
  end
end
