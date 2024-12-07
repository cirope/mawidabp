module Organizations::Options
  extend ActiveSupport::Concern

  included do
    attr_accessor :option_type

    after_create_commit :create_options
  end

  TYPES = [
    'manual_scores', 'control_objective_item_scores'
  ]

  DEFAULT_SCORES = {
    satisfactory:                   100,
    needs_minor_improvements:       80,
    needs_improvement:              60,
    needs_significant_improvements: 40,
    unsatisfactory:                 20
  }

  def current_scores_by type
    scores = scores_by type

    scores.present? ? sorted_scores(scores.first&.last) : []
  end

  def scores_by type
    if options&.dig(type)
      options[type].sort_by { |score, value| score.to_i }.reverse.to_h
    end
  end

  def scores_for type, date
    epoch = (date || Time.zone.now).to_i

    sorted_scores(
      scores_by(type).detect { |date, values| date.to_i <= epoch }&.last
    )
  end

  def create_options
    update! options: default_scores
  end

  private

    def sorted_scores scores
      if scores.present?
        scores.sort_by { |score, value| value.to_i }.reverse.to_h
      else
        {}
      end
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
