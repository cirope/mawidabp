module SettingsHelper
  include Parameters::Risk
  include Parameters::Priority
  include Parameters::Relevance
  include Parameters::Qualification

  def relevances show_value: !USE_SHORT_RELEVANCE,
                 date:       nil

    Setting.relevances show_value: show_value,
                       date:       date,
                       translate:  true
  end

  def qualifications show_value: !SHOW_SHORT_QUALIFICATIONS,
                     date:       nil

    Setting.qualifications show_value: show_value,
                           date:       date,
                           translate:  true
  end

  def risks date: nil
    Setting.risks date:       date,
                  translate:  true
  end

  def priorities date: nil
    Setting.priorities date:       date,
                       translate:  true
  end
end
