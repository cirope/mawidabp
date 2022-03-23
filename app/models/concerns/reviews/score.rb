module Reviews::Score
  extend ActiveSupport::Concern

  def score_text
    _score_text score_array
  end

  def score_alt_text
    scored_by_splitted_effectiveness? ? _score_text(score_array alt: true) : '-'
  end

  def sorted_scores type: :effectiveness
    date = conclusion_final_review&.issue_date || created_at

    case type
    when :effectiveness, :manual, :splitted_effectiveness
      self.class.scores(date).to_a.sort do |s1, s2|
        s2[1].to_i <=> s1[1].to_i
      end
    when :weaknesses, :none, :weaknesses_alt
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

  def score_by_splitted_effectiveness date
    design_relevance_sum     = 0
    design_total             = 0
    sustantive_relevance_sum = 0
    sustantive_total         = 0

    control_objective_items_for_score.each do |coi|
      unless coi.exclude_from_score
        if coi.design_score.present?
          design_relevance_sum += coi.relevance.to_f
          design_total         += coi.effectiveness(exclude_non_design_scores: true) * coi.relevance.to_f
        end

        if coi.sustantive_score.present? || coi.compliance_score.present?
          sustantive_relevance_sum += coi.relevance.to_f
          sustantive_total         += coi.effectiveness(exclude_design_score: true) * coi.relevance.to_f
        end
      end
    end

    self.score = if design_relevance_sum > 0
                   (design_total / design_relevance_sum.to_f).round
                 else
                   100.0
                 end

    self.score_alt = if sustantive_relevance_sum > 0
                       (sustantive_total / sustantive_relevance_sum.to_f).round
                     else
                       100.0
                     end
  end

  def score_by_weighted_weaknesses date
    weaknesses      = has_final_review? ? final_weaknesses : self.weaknesses
    total           = 0
    high_score      = 150
    medium_score    = 50
    hundred_percent = 100

    scores = weaknesses.select { |w| w.state_weight > 0 }.group_by do |w|
      [w.risk_weight, w.state_weight, w.age_weight(date: date)]
    end

    total = scores.sum do |row, weaknesses|
      row.unshift weaknesses.size

      row.inject &:*
    end

    if total <= medium_score
      self.score = hundred_percent - total
    elsif total <= high_score
      min = ((hundred_percent - medium_score.next) / 3).to_i
      max = hundred_percent - medium_score.next

      self.score = max - ((total * min) / high_score)
    else
      min = 1
      max = 16

      self.score = max - ((total * min) / high_score.next).to_i
    end
  end

  def scored_by_weaknesses?
    score_type == 'weaknesses'
  end

  def scored_by_splitted_effectiveness?
    score_type == 'splitted_effectiveness'
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
      splitted_effectiveness = USE_SCOPE_CYCLE &&
                               REVIEW_SCOPES[plan_item&.scope]&.fetch(:type, nil) == :cycle

      by_weaknesses_alt = Current.conclusion_pdf_format == 'nbc'

      if splitted_effectiveness
        :splitted_effectiveness
      elsif by_weaknesses
        score_type&.to_sym == :none ? :none : :weaknesses
      elsif SHOW_REVIEW_EXTRA_ATTRIBUTES
        :manual
      elsif by_weaknesses_alt
        :weaknesses_alt
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
      when :splitted_effectiveness
        score_by_splitted_effectiveness date
      when :manual, :none
        self.score = 100
      when :weaknesses_alt
        score_by_weighted_weaknesses date
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
