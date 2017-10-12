module Weaknesses::Progress
  extend ActiveSupport::Concern

  included do
    before_save :update_progress
  end

  def allow_progress_edition?
    progress_edition_states = [
      Finding::STATUS[:being_implemented]
    ]

    progress_edition_states.include? state
  end

  private

    def update_progress
      if state_changed? && progress_completed_state?
        self.progress = 100
      elsif state_changed? && being_implemented?
        self.progress = 25
      elsif state_changed? && progress_reset_state?
        self.progress = 0
      end
    end

    def progress_completed_state?
      progress_completed_states = [
        Finding::STATUS[:implemented],
        Finding::STATUS[:implemented_audited]
      ]

      progress_completed_states.include? state
    end

    def progress_reset_state?
      progress_reset_states = [
        Finding::STATUS[:awaiting],
        Finding::STATUS[:assumed_risk],
        Finding::STATUS[:revoked],
        Finding::STATUS[:criteria_mismatch]
      ]

      progress_reset_states.include? state
    end
end
