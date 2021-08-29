module Parameters::Score
  extend ActiveSupport::Concern

  DEFAULT_SCORES = {
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
    def scores date = nil
      scores_on_date = scores_for_date(date || Time.zone.today)

      DEFAULT_SCORES.merge(
        scores_on_date.symbolize_keys
      ).sort_by { |k, v| v }.reverse.to_h
    end

    def scores_by_weaknesses date = nil
      scores = JSON.parse ENV['SCORE_BY_WEAKNESS'] || '{}'

      DEFAULT_SCORE_BY_WEAKNESSES.merge scores.symbolize_keys
    end

    def scores_by_weighted date = nil
      scores_for_date(date || Time.zone.today)
    end

    private

      def scores_for_date date
        scores = JSON.parse ENV['REVIEW_SCORES'] || '{}'

        if scores.present?
          scores.detect do |date_string, _|
            score_date = Date.parse date_string

            score_date <= date
          end&.last || {}
        else
          {}
        end
      end
  end
end
