module PlanItems::BestPractices
  extend ActiveSupport::Concern

  included do
    has_many :best_practice_projects, dependent: :destroy
    has_many :best_practices, through: :best_practice_projects

    accepts_nested_attributes_for :best_practice_projects,
      allow_destroy: true, reject_if: :all_blank
  end
end
