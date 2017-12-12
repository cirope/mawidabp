class ProcessControlComment < ApplicationRecord
  include Auditable
  include ProcessControlComments::UpdateCallbacks

  validates :process_control, :auditor_comment, presence: true

  belongs_to :review
  belongs_to :process_control
end
