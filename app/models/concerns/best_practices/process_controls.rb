module BestPractices::ProcessControls
  extend ActiveSupport::Concern

  included do
    has_many :process_controls, -> { order("#{ProcessControl.quoted_table_name}.#{ProcessControl.qcn('order')} ASC") },
      dependent: :destroy, after_add: :assign_best_practice

    accepts_nested_attributes_for :process_controls, allow_destroy: true
  end

  private

    def assign_best_practice process_control
      process_control.best_practice = self
    end
end
