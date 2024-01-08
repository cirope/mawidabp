module RiskControlObjectives::Validation
  extend ActiveSupport::Concern

  included do
    validate :uniqueness_control_objective
  end

  private

    def uniqueness_control_objective
      if control_objective_id.present?
        rcos = risk.risk_control_objectives.reject do |rco|
          rco == self || rco.marked_for_destruction?
        end

        if rcos.select { |rco| rco.control_objective_id.to_i == control_objective_id.to_i }.any?
          errors.add :control_objective, :taken
        end
      end
    end
end
