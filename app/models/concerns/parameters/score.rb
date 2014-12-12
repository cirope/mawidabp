module Parameters::Score
  extend ActiveSupport::Concern

  SCORE_TYPES = {
    satisfactory: 80,
    improve: 50,
    unsatisfactory: 0
  }

  module ClassMethods
    def scores
      SCORE_TYPES
    end
  end
end
