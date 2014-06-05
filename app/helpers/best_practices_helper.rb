module BestPracticesHelper
  def nested_process_controls
    @best_practice.process_controls.build if @best_practice.process_controls.blank?

    @best_practice.process_controls
  end
end
