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
      APP_CONFIG['highest_score_organizations'].keys.include?(Organization.current_id) &&
        created > APP_CONFIG['highest_score_organizations'][Organization.current_id] ?
        HIGHEST_SCORE_TYPES : SCORE_TYPES
    end
  end
end








