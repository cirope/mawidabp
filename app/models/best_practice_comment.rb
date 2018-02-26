class BestPracticeComment < ApplicationRecord
  include Auditable
  include BestPracticeComments::UpdateCallbacks

  validates :best_practice, :auditor_comment, presence: true

  belongs_to :review
  belongs_to :best_practice
end
