module Findings::StateDates
  extend ActiveSupport::Concern

  included do
    before_save :put_state_dates, if: :state_changed?
  end

  def version_implemented_at
    if implemented? || has_final_status?
      version = versions.reverse.detect do |v|
        finding_state_in_version(v) == Finding::STATUS[:implemented]
      end

      version&.created_at&.to_date ||
        follow_up_date             ||
        solution_date              ||
        Time.zone.today
    end
  end

  def version_closed_at
    if has_final_status?
      if versions.empty?
        solution_date || Time.zone.today
      else
        versions.last.created_at.to_date
      end
    end
  end

  private

    def put_state_dates
      if being_implemented?
        self.implemented_at = nil
      elsif implemented?
        self.implemented_at = Time.zone.today
      elsif has_final_status?
        self.closed_at = Time.zone.today
      end
    end

    def finding_state_in_version version
      changes = case version.object_changes.class
                when Hash
                  version.object_changes
                when String # Just for Oracle
                  JSON.parse version.object_changes
                end

      changes && Array(changes['state']).last
    end
end
