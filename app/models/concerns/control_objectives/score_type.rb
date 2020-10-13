module ControlObjectives::ScoreType
  extend ActiveSupport::Concern

  included do
    enum score_type: {
      option:     'option',
      percentage: 'percentage'
    }
  end

  module ClassMethods
    def default_score_type
      score_types[:option]
    end
  end
end
