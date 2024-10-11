module ConclusionReviews::Options
  extend ActiveSupport::Concern

  included do
    serialize :options, JSON unless POSTGRESQL_ADAPTER
  end

  def exclude_implemented_audited_findings
    option_value 'exclude_implemented_audited_findings'
  end

  def exclude_criteria_mismatch_findings
    option_value 'exclude_criteria_mismatch_findings'
  end

  def option_value option
    options.dig(option) == '1'
  end
end

