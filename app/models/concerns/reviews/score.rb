module Reviews::Score
  extend ActiveSupport::Concern

  def score_text
    score = score_array

    if SHOW_REVIEW_EXTRA_ATTRIBUTES
      (manual_score || '-').to_s
    else score
      [I18n.t("score_types.#{score.first}"), "(#{score.last}%)"].join(' ')
    end
  end

  def sorted_scores
    self.class.scores.to_a.sort { |s1, s2| s2[1].to_i <=> s1[1].to_i }
  end

  def score_array
    scores = sorted_scores
    count  = scores.size + 1

    effectiveness

    score_description = scores.detect do |s|
      count -= 1
      score >= s[1].to_i
    end

    self.achieved_scale = count
    self.top_scale      = scores.size

    [score_description ? score_description[0] : '-', score]
  end

  def control_objective_items_for_score
    control_objective_items.reject &:exclude_from_score
  end

  def effectiveness
    relevance_sum = control_objective_items_for_score.inject(0.0) do |acc, coi|
      acc + coi.relevance.to_f
    end
    total = control_objective_items_for_score.inject(0.0) do |acc, coi|
      acc + coi.effectiveness * coi.relevance.to_f
    end

    self.score = relevance_sum > 0 ? (total / relevance_sum.to_f).round : 100.0
  end

  private

    def calculate_score
      score_array
    end
end
