module ControlObjectiveItemsHelper
  def control_objective_relevance_text(control_objective_item)
    relevance = control_objective_item.relevance
    text = control_objective_item.relevance_label

    if text.blank? || text == '-'
      text
    else
      "#{text} (#{relevance})"
    end
  end

  def control_objective_effectiveness(control_objective_item)
    if control_objective_item.exclude_from_score
      content_tag(
        :abbr,
        "#{control_objective_item.effectiveness}%",
        :class => 'strike',
        :title => t('control_objective_item.excluded_from_score')
      )
    else
      "#{control_objective_item.effectiveness}%"
    end
  end

  def control_objective_qualification_text(qualification, created_at)
    text = name_for_option_value(
      ControlObjectiveItem.qualifications, qualification)

    text.blank? || text == '-' ? text : "#{text} (#{qualification})"
  end

  def next_control_objective_work_paper_code(control_objective_item)
    code_from_review = next_review_work_paper_code(
      control_objective_item.review)
    code_from_control_objective = control_objective_item.work_papers.reject(
      &:marked_for_destruction?).map(&:code).sort.last

    [code_from_review, code_from_control_objective].compact.max
  end

  def control_objective_weaknesses_link(control_objective_item)
    weaknesses = control_objective_item.is_in_a_final_review? ?
      control_objective_item.final_weaknesses : control_objective_item.weaknesses

    count = weaknesses.count

    link_to_unless count.zero?, count, weaknesses_path(control_objective: control_objective_item)
  end

  def auditor_comment_options
    CONCLUSION_OPTIONS.map { |option| [option, option] }
  end

  def previous_effectiveness(control_objective_item)
    coi = control_objective_item.previous_effectiveness

    coi.nil? ? t('message.no_results_found') :  t('control_objective_item.previous_effectiveness', effectiveness: coi.effectiveness)
  end
end
