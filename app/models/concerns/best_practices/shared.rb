module BestPractices::Shared
  extend ActiveSupport::Concern

  included do
    before_save :mark_control_objectives_as_shared
  end

  private

    def mark_control_objectives_as_shared
      if shared_changed? && shared
        process_controls.each do |process_control|
          process_control.updated_at_will_change!

          process_control.control_objectives.each do |control_objective|
            control_objective.updated_at_will_change!
          end
        end
      end
    end
end
