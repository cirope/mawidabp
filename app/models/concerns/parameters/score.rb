module Parameters::Score
  extend ActiveSupport::Concern

  HIGHEST_SCORE_TYPES = {
    satisfactory: 80,
    improve: 65,
    unsatisfactory: 0
  }

  SCORE_TYPES = {
    satisfactory: 80,
    improve: 50,
    unsatisfactory: 0
  }

  module ClassMethods
    def scores(created)
      highest_score = JSON.parse ENV['HIGHEST_SCORE_ORGANIZATIONS']
      highest_score.keys.include?(Organization.current_id.to_s) &&
        created > highest_score[Organization.current_id.to_s] ? HIGHEST_SCORE_TYPES : SCORE_TYPES
    end
  end
end
