module SettingsHelper
  include Parameters::Risk
  include Parameters::Priority
  include Parameters::Relevance
  include Parameters::Qualification

  def relevances show_value: !USE_SHORT_RELEVANCE, date: nil
    if REVIEW_MANUAL_SCORE
      Current.organization.scores_for(
        type: 'relevance_scores', date: date
      )
    else
      RELEVANCE_TYPES.map do |k, v|
        text = [
          t("relevance_types.#{k}"),
          ("(#{v})" if show_value)
        ].compact.join(' ')

        [text, v]
      end
    end
  end

  def qualifications show_value: !SHOW_SHORT_QUALIFICATIONS, date: nil
    if REVIEW_MANUAL_SCORE
      Current.organization.scores_for(
        type: 'control_objective_item_scores', date: date
      )
    else
      ::QUALIFICATION_TYPES.map do |k, v|
        text = [
          t("qualification_types.#{k}"),
          ("(#{v})" if show_value)
        ].compact.join(' ')

        [text, v]
      end
    end
  end

  def risks
    RISK_TYPES.map do |k, v|
      [[t("risk_types.#{k}"), "(#{v})"].join(' '), v]
    end
  end

  def priorities date: nil
    if SHOW_CONDENSED_PRIORITIES
      PRIORITY_TYPES.map do |k, v|
        [t("priority_types.#{k}"), v]
      end
    elsif REVIEW_MANUAL_SCORE
      Current.organization.scores_for(
        type: 'priority_scores', date: date
      )
    else
      PRIORITY_TYPES.map do |k, v|
        [[t("priority_types.#{k}"), "(#{v})"].join(' '), v]
      end
    end
  end
end
