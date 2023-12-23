module Findings::GraphHelpers
  extend ActiveSupport::Concern

  module ClassMethods
    def findings_for_graph findings
      labels    = []
      series    = []
      from_date = 11.months.ago.beginning_of_month.to_date
      end_date  = Date.today.beginning_of_month

      latest_findings = findings.
        where(origination_date: from_date..end_date).
        group("to_char(origination_date, 'mm-yy')").
        order(to_char_origination_date_mm_yy: :asc)

      while end_date >= from_date
        labels << I18n.l(from_date, format: '%m-%y')

        from_date += 1.month
      end

      incomplete = latest_findings.with_pending_status.count
      completed  = latest_findings.with_completed_status.count

      series << labels.map { |label| incomplete[label].to_i }
      series << labels.map { |label| completed[label].to_i  }

      { labels: labels, series: series }
    end
  end
end
