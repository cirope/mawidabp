module Organizations::Options
  extend ActiveSupport::Concern

  DEFAULT_SCORES = {
    satisfactory:                   100,
    needs_minor_improvements:       80,
    needs_improvement:              60,
    needs_significant_improvements: 40,
    unsatisfactory:                 20
  }

  def current_scores
    values = options.values.first

    values.sort_by { |key, value| value }.reverse.to_h
  end
end
