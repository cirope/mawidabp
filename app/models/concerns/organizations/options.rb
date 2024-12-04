module Organizations::Options
  extend ActiveSupport::Concern

  included do
    after_create_commit :create_options
  end

  DEFAULT_SCORES = {
    satisfactory:                   100,
    needs_minor_improvements:       80,
    needs_improvement:              60,
    needs_significant_improvements: 40,
    unsatisfactory:                 20
  }

  def current_scores
    sorted_scores manual_scores.first.last
  end

  def manual_scores
    options['manual_scores'].sort_by { |score, value| score.to_i }.reverse.to_h
  end

  def create_options
    update! options: default_scores
  end

  def scores_for date
    epoch = (date || Time.zone.now).to_i

    sorted_scores(
      manual_scores.detect { |date, values| date.to_i <= epoch }&.last
    )
  end

  private

    def sorted_scores scores
      scores.sort_by { |score, value| value.to_i }.reverse.to_h if scores.present?
    end

    def default_scores
      scores = {}

      Organization::DEFAULT_SCORES.each do |key, value|
        score         = I18n.t "options.manual_scores.#{key}"
        scores[score] = value
      end

      { manual_scores: { Time.zone.now.to_i => scores } }
    end
end
