module Reviews::Score
  extend ActiveSupport::Concern

  def score_text
    score = score_array

    score ? [I18n.t("score_types.#{score.first}"), "(#{score.last}%)"].join(' ') : ''
  end

  def score_array
    scores = self.class.scores.to_a
    count  = scores.size + 1

    effectiveness

    scores.sort! { |s1, s2| s2[1].to_i <=> s1[1].to_i }

    score_description = scores.detect do |s|
      count -= 1
      score >= s[1].to_i
    end

    self.achieved_scale = count
    self.top_scale      = scores.size

    [score_description ? score_description[0] : '-', self.score]
  end

  private

    def calculate_score
      score_array
    end
end
