module ConclusionReviews::Options
  extend ActiveSupport::Concern

  included do
    serialize :options, JSON unless POSTGRESQL_ADAPTER
  end

  def exclude_implemented_audited_findings
    options&.fetch 'exclude_implemented_audited_findings', nil
  end
  alias_method :exclude_implemented_audited_findings?, :exclude_implemented_audited_findings

  def exclude_implemented_audited_findings= value
    assign_option 'exclude_implemented_audited_findings', value == true || value == '1'
  end

  def exclude_criteria_mismatch_findings
    options&.fetch 'exclude_criteria_mismatch_findings', nil
  end
  alias_method :exclude_criteria_mismatch_findings?, :exclude_criteria_mismatch_findings

  def exclude_criteria_mismatch_findings= value
    assign_option 'exclude_criteria_mismatch_findings', value == true || value == '1'
  end

  private

    def assign_option name, value
      self.options ||= {}
      prev_value = self.options[name]

      options_will_change! unless prev_value == value

      self.options[name] = value
    end
end
