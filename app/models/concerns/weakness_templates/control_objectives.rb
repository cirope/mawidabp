module WeaknessTemplates::ControlObjectives
  extend ActiveSupport::Concern

  included do
    has_many :control_objective_weakness_template_relations, dependent: :destroy
    has_many :control_objectives, through: :control_objective_weakness_template_relations

    accepts_nested_attributes_for :control_objective_weakness_template_relations,
      allow_destroy: true, reject_if: :all_blank
  end
end
