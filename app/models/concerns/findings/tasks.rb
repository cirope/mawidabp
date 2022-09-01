module Findings::Tasks
  extend ActiveSupport::Concern

  included do
    before_save :mark_tasks_as_finished

    has_many :tasks, -> { order due_on: :asc }, dependent: :destroy

    accepts_nested_attributes_for :tasks, allow_destroy: true
  end

  def next_task_expiration
    tasks.where(status: [Task.statuses['pending'], Task.statuses['in_progress']],
                due_on: Date.today..)
         .first
         &.due_on
  end

  private

    def mark_tasks_as_finished
      finish_tasks = state &&
        state_changed? &&
        (state.presence_in(Finding::FINAL_STATUS) || repeated?)

      tasks.each &:finished! if finish_tasks
    end
end
