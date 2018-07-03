class Task < ApplicationRecord
  include Auditable
  include Tasks::Status
  include Tasks::Validations

  belongs_to :finding, touch: true

  def to_s
    description
  end
end
