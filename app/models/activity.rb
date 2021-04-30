class Activity < ApplicationRecord
  include Auditable
  include Activities::DestroyValidation
  include Activities::Validation

  belongs_to :activity_group, inverse_of: :activities

  def to_s
    name
  end
end
