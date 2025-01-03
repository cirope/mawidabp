module ControlObjectiveItems::Scores
  extend ActiveSupport::Concern

  def design_score_text show_value: false
    score_text_for design_score, show_value
  end

  def compliance_score_text show_value: false
    score_text_for compliance_score, show_value
  end

  def sustantive_score_text show_value: false
    score_text_for sustantive_score, show_value
  end

  private

    def score_text_for score, show_value
      if REVIEW_MANUAL_SCORE
        Current.organization.control_objective_item_scores_text_for(
          date: created_at, value: score
        )
      else
        full_score = self.class.qualifications.detect do |r|
          r.last == score
        end

        qualification_text full_score, show_value
      end
    end

    def qualification_text score, show_value
      if score.present?
        text = I18n.t("qualification_types.#{score.first}")

        return show_value ? [text, "(#{score.last})"].join(' ') : text
      end
    end
end
