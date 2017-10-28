module Oportunities::Scopes
  extend ActiveSupport::Concern

  included do
    scope :all_for_report, -> {
      where(
        state: Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).values,
        final: true
      ).order(state: :asc)
    }
  end
end
