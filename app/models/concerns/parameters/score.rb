module Parameters::Score
  extend ActiveSupport::Concern

  SCORE_TYPES = {
    satisfactory: 80,
    improve: 50,
    unsatisfactory: 0
  }

  DEFAULT_SCORE_BY_WEAKNESSES = {
    adequate: 100,
    require_some_improvements: 80,
    require_improvements: 60,
    require_lots_of_improvements: 40,
    inadequate: 0
  }

  module ClassMethods
    def scores
      SCORE_TYPES
    end

    def scores_by_weaknesses
      scores = JSON.parse ENV['SCORE_BY_WEAKNESS'] || '{}'

      DEFAULT_SCORE_BY_WEAKNESSES.merge scores.symbolize_keys
    end
  end
end
