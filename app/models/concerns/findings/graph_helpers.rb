module Findings::GraphHelpers
  extend ActiveSupport::Concern

  module ClassMethods
    def graph_findings findings
      incomplete = latest_findings(findings).with_pending_status.count
      completed  = latest_findings(findings).with_completed_status.count

      incomplete = [] if incomplete.blank?
      completed  = [] if completed.blank?

      [
        { name: I18n.t('findings.graphs.incomplete'), data: incomplete },
        { name: I18n.t('findings.graphs.completed'),  data: completed  }
      ]
    end

    private

      def latest_findings findings
        from_date = 11.months.ago.beginning_of_month
        end_date  = Date.today

        latest_findings = findings.
          where(origination_date: from_date..end_date).
          group_by_month(:origination_date)
      end
  end
end
