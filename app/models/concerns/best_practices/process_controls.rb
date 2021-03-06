module BestPractices::ProcessControls
  extend ActiveSupport::Concern

  included do
    has_many :process_controls, -> { order order: :asc }, dependent: :destroy, after_add: :assign_best_practice
    has_many :control_objectives, through: :process_controls

    accepts_nested_attributes_for :process_controls, allow_destroy: true
  end

  private

    def assign_best_practice process_control
      process_control.best_practice = self
    end
end
