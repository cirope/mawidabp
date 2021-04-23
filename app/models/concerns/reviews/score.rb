module Reviews::Score
  extend ActiveSupport::Concern

  def score_text
    _score_text score_array
  end

  def score_alt_text
    scored_by_splitted_weaknesses? ? _score_text(score_array alt: true) : '-'
  end

  def sorted_scores type: :effectiveness
    date = conclusion_final_review&.issue_date || created_at

    case type
    when :effectiveness, :manual, :splitted_weaknesses
      self.class.scores(date).to_a.sort do |s1, s2|
        s2[1].to_i <=> s1[1].to_i
      end
    when :weaknesses, :none
      self.class.scores_by_weaknesses(date).to_a.sort do |s1, s2|
        s2[1].to_i <=> s1[1].to_i
      end
    end
  end

  def score_array date: (conclusion_final_review&.issue_date || Time.zone.today), alt: false
    type   = guess_score_type
    scores = sorted_scores type: type
    count  = scores.size + 1

    calculate_score_for type, date

    score = if alt
              (manual_score_alt || score_alt).to_i
            else
              (manual_score || self.score).to_i
            end

    score_description = scores.detect do |s|
      count -= 1
      score >= s[1].to_i
    end

    self.score_type     = type.to_s
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

  def score_by_weaknesses date
    weaknesses = has_final_review? ? final_weaknesses : self.weaknesses

    scores = weaknesses.not_revoked.map { |w| score_for w, date }
    total  = scores.compact.sum

    self.score = total <= 50 ? (100 - total * 2).round : 0
  end

  def score_by_splitted_weaknesses date
    weaknesses = has_final_review? ? final_weaknesses : self.weaknesses

    grouped_weaknesses = weaknesses.not_revoked.group_by do |w|
      w.design? ? :design : :sustantive
    end

    # Must always have a key, so it "calculates" the score
    grouped_weaknesses[:design]     ||= []
    grouped_weaknesses[:sustantive] ||= []

    grouped_weaknesses.each do |type, weaknesses|
      scores = weaknesses.map { |w| score_for w, date }
      total  = scores.compact.sum
      score  = total <= 50 ? (100 - total * 2).round : 0

      if type == :design
        self.score = score
      else
        self.score_alt = score
      end
    end
  end

  def scored_by_weaknesses?
    score_type == 'weaknesses'
  end

  def scored_by_splitted_weaknesses?
    score_type == 'splitted_weaknesses'
  end

  private

    def _score_text score
      if SHOW_REVIEW_EXTRA_ATTRIBUTES
        (manual_score || '-').to_s
      elsif score
        [I18n.t("score_types.#{score.first}"), "(#{score.last}%)"].join(' ')
      end
    end

    def guess_score_type
      by_weaknesses = ORGANIZATIONS_WITH_REVIEW_SCORE_BY_WEAKNESS.include? Current.organization&.prefix
      splitted_weaknesses = by_weaknesses &&
                              USE_SCOPE_CYCLE &&
                              REVIEW_SCOPES[plan_item&.scope]&.fetch(:type, nil) == :cycle

      if splitted_weaknesses
        :splitted_weaknesses
      elsif by_weaknesses
        score_type&.to_sym == :none ? :none : :weaknesses
      elsif SHOW_REVIEW_EXTRA_ATTRIBUTES
        :manual
      else
        :effectiveness
      end
    end

    def calculate_score_for type, date
      case type
      when :effectiveness
        effectiveness
      when :weaknesses
        score_by_weaknesses date
      when :splitted_weaknesses
        score_by_splitted_weaknesses date
      when :manual, :none
        self.score = 100
      end
    end

    def score_for weakness, date
      if weakness.take_as_old_for_score? date: date
        old_score_for weakness
      elsif weakness.take_as_repeated_for_score? date: date
        repeated_score_for weakness
      else
        normal_score_for weakness
      end
    end

    def normal_score_for weakness
      risks = weakness.class.risks

      case weakness.risk
      when risks[:high]
        weakness_weights[:normal_high]
      when risks[:medium]
        weakness_weights[:normal_medium]
      when risks[:low], risks[:none]
        weakness_weights[:normal_low]
      end
    end

    def repeated_score_for weakness
      risks = weakness.class.risks

      case weakness.risk
      when risks[:high]
        weakness_weights[:repeated_high]
      when risks[:medium]
        weakness_weights[:repeated_medium]
      when risks[:low], risks[:none]
        weakness_weights[:repeated_low]
      end
    end

    def old_score_for weakness
      risks = weakness.class.risks

      case weakness.risk
      when risks[:high]
        weakness_weights[:old_high]
      when risks[:medium]
        weakness_weights[:old_medium]
      when risks[:low], risks[:none]
        weakness_weights[:old_low]
      end
    end

    def calculate_score
      score_array
    end

    def weakness_weights
      scores = JSON.parse ENV['WEAKNESS_WEIGHTS'] || '{}'

      {
        normal_high:     6.0,
        normal_medium:   2.0,
        normal_low:      1.0,
        repeated_high:   10.0,
        repeated_medium: 3.0,
        repeated_low:    1.5,
        old_high:        10.5,
        old_medium:      8.5,
        old_low:         7.0
      }.merge scores.symbolize_keys
    end
end
