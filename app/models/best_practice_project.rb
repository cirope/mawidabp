class BestPracticeProject < ApplicationRecord
  include Auditable

  belongs_to :best_practice
  belongs_to :plan_item
end
