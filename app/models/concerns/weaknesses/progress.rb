module Weaknesses::Progress
  extend ActiveSupport::Concern

  included do
    PROGRESS_COMPLETED_STATES = [
      Finding::STATUS[:implemented],
      Finding::STATUS[:implemented_audited]
    ]

    PROGRESS_RESET_STATES = [
      Finding::STATUS[:awaiting],
      Finding::STATUS[:assumed_risk],
      Finding::STATUS[:notify],
      Finding::STATUS[:incomplete],
      Finding::STATUS[:revoked],
      Finding::STATUS[:criteria_mismatch]
    ]

    PROGRESS_EDITION_STATES = [
      Finding::STATUS[:being_implemented]
    ]

    before_save :update_progress
  end

  def allow_progress_edition?
    self.class.allow_progress_edition_for? state
  end

  module ClassMethods
    def allow_progress_edition_for? state
      PROGRESS_EDITION_STATES.include? state
    end

    def default_progress_for state: nil
      if PROGRESS_COMPLETED_STATES.include? state
        100
      elsif PROGRESS_RESET_STATES.include? state
        0
      else
        25
      end
    end
  end

  private

    def update_progress
      if state_changed? && progress_completed_state?
        self.progress = 100
      elsif state_changed? && being_implemented?
        self.progress = 25
      elsif progress_reset_state?
        self.progress = 0
      end
    end

    def progress_completed_state?
      PROGRESS_COMPLETED_STATES.include? state
    end

    def progress_reset_state?
      PROGRESS_RESET_STATES.include? state
    end
end
