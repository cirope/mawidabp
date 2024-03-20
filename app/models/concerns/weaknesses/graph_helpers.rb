module Weaknesses::GraphHelpers
  extend ActiveSupport::Concern

  module ClassMethods
    def weaknesses_for_graph weaknesses
      series = []
      grouped_weaknesses = weaknesses.group_by(&:state)

      grouped_weaknesses.each do |status, weaknesses|
        series << {
          name: weaknesses.first.state_text, data: weaknesses.size
        }
      end

      series
    end

    def pending_weaknesses_for_graph weaknesses
      series = []
      being_implemented_counts = {
        current: 0, current_rescheduled: 0, stale: 0 , stale_rescheduled: 0
      }

      weaknesses.with_pending_status.each do |w|
        unless w.stale?
          unless w.rescheduled?
            being_implemented_counts[:current] += 1
          else
            being_implemented_counts[:current_rescheduled] += 1
          end
        else
          unless w.rescheduled?
            being_implemented_counts[:stale] += 1
          else
            being_implemented_counts[:stale_rescheduled] += 1
          end
        end
      end

      being_implemented_counts.each do |label, value|
        unless value == 0
          series << {
            name: I18n.t("follow_up_committee_report.weaknesses_being_implemented_#{label}", count: value),
            data: value
          }
        end
      end

      series
    end
  end
end
