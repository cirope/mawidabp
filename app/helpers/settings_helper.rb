module SettingsHelper
  include Parameters::Risk
  include Parameters::Priority
  include Parameters::Relevance
  include Parameters::Qualification

  def relevances
    RELEVANCE_TYPES.map { |k,v| [[t("relevance_types.#{k}"),"(#{v})"].join(' '), v] }
  end

  def qualifications
    QUALIFICATION_TYPES.map { |k,v| [[t("qualification_types.#{k}"),"(#{v})"].join(' '), v] }
  end

  def risks
    RISK_TYPES.map { |k,v| [[t("risk_types.#{k}"), "(#{v})"].join(' '), v] }
  end

  def priorities
    PRIORITY_TYPES.map { |k,v| [[t("priority_types.#{k}"), "(#{v})"].join(' '), v] }
  end
end
