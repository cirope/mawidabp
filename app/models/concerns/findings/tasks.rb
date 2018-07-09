module Findings::Tasks
  extend ActiveSupport::Concern

  included do
    before_save :mark_tasks_as_finished

    has_many :tasks, -> { order due_on: :asc }, dependent: :destroy

    accepts_nested_attributes_for :tasks, allow_destroy: true
  end

  def task_rescheduled?
    tasks.any?(&:rescheduled?)
  end

  private

    def mark_tasks_as_finished
      if state && state_changed? && state.presence_in(Finding::FINAL_STATUS)
        tasks.each &:finished!
      end
    end
end
