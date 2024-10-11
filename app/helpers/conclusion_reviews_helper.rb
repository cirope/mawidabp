module ConclusionReviewsHelper
  def score_text_for conclusion_review
    if USE_SCOPE_CYCLE && conclusion_review.review.control_objective_items_for_score.blank?
      I18n.t 'score_types.none'
    else
      conclusion_review.review.score_text
    end
  end

  def score_alt_text_for conclusion_review
    if conclusion_review.review.control_objective_items_for_score.blank?
      I18n.t 'score_types.none'
    else
      conclusion_review.review.score_alt_text
    end
  end

  def conclusion_options
    CONCLUSION_OPTIONS.map { |option| [option, option] }
  end

  def evolution_options conclusion_review
    draft_issue_date = conclusion_review&.review&.conclusion_draft_review&.issue_date
    code_change_date = CONCLUSION_REVIEW_FEATURE_DATES['new_conclusion_evolution_combination']&.to_date

    if draft_issue_date && code_change_date && draft_issue_date < code_change_date
      EVOLUTION_OPTIONS.map { |option| [option, option] }
    else
      NEW_EVOLUTION_OPTIONS.map { |option| [option, option] }
    end
  end

  def conclusion_review_options_collection
    Array CONCLUSION_REVIEW_OPTIONS.dup
  end

  def conclusion_review_input_option form, review, option, readonly: false
    option_key    = option.last
    resource_name = review.model_name.param_key

    input_html = {
      id:       "#{resource_name}_#{option_key}_options",
      name:     "#{resource_name}[options][#{option_key}]",
      checked:  review.option_value(option_key),
      readonly: readonly
    }

    form.input :options,
      as:         :boolean,
      label:      option.first,
      input_html: input_html
  end
end
