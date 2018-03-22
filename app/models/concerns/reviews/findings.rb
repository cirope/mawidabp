module Reviews::Findings
  extend ActiveSupport::Concern

  included do
    has_many :weaknesses,         through: :control_objective_items
    has_many :oportunities,       through: :control_objective_items
    has_many :final_weaknesses,   through: :control_objective_items
    has_many :final_oportunities, through: :control_objective_items
  end
end
