module Findings::GraphHelpers
  extend ActiveSupport::Concern

  module ClassMethods
    def findings_for_graph findings
      from_date = 11.months.ago.beginning_of_month.to_date
      end_date  = Date.today.beginning_of_month

      latest_findings = findings.
        where(origination_date: from_date..end_date).
        group_by_month(:origination_date)

      incomplete = latest_findings.with_pending_status.count
      completed  = latest_findings.with_completed_status.count

      [
        { name: I18n.t('findings.graphs.incomplete'), data: incomplete },
        { name: I18n.t('findings.graphs.completed'),  data: completed  }
      ]
    end
  end
end
