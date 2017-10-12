module ReviewsHelper
  def show_review_with_close_date_as_abbr(review)
    close_date = review.conclusion_final_review.try(:close_date)
    review_data = close_date ?
      t('review.review_data.close_date', :date => l(close_date, :format => :long)) :
      t('review.review_data.without_close_date')

    content_tag(:abbr, review.identification, :title => review_data)
  end

  def show_review_identification_with_score_as_abbr(review)
    content_tag :abbr, review.identification, :title => review.score_text
  end

  def review_plan_item_field(form, readonly)
    require 'ostruct' unless defined? OpenStruct

    grouped_plan_items = PlanItem.list_unused(@review.period_id).group_by(
      &:business_unit_type)

    business_unit_types = grouped_plan_items.map do |but, plan_items|
      sorted_plan_items = plan_items.sort_by(&:project)

      OpenStruct.new({:name => but.name, :plan_items => sorted_plan_items})
    end

    form.grouped_collection_select :plan_item_id, business_unit_types,
      :plan_items, :name, :id, :project, {:prompt => true},
      {:class => 'form-control', :disabled => readonly}
  end

  def review_business_unit_type_text(review)
    review.plan_item.try(:business_unit).try(:business_unit_type).try(:name)
  end

  def review_business_unit_text(review)
    review.plan_item.try(:business_unit).try(:name)
  end

  def user_assignment_type_field(form, inline = true, disabled = false)
    input_options = { disabled: disabled, data: { review_role: true } }
    options = ReviewUserAssignment::TYPES.map do |k, v|
      [t("review.user_assignment.type_#{k}"), v]
    end

    form.input :assignment_type, collection: sort_options_array(options),
      prompt: true, label: false, input_html: input_options
  end

  def user_assignment_type_text(type)
    content_tag(:span, user_assignment_type_name_for(type), :class => :bold)
  end

  def user_assignment_type_name_for(type)
    t "review.user_assignment.type_#{ReviewUserAssignment::TYPES.invert[type]}"
  end

  def next_review_work_paper_code(review)
    code_prefix = t('code_prefixes.work_papers_in_control_objectives')

    review ? review.last_control_objective_work_paper_code(prefix: code_prefix) :
      "#{code_prefix} 0".strip
  end

  def show_readonly_review_survey(review)
    link_for_download = link_to(
      t('label.download'),
      :action => :survey_pdf, :id => review, :_ts => Time.now.to_i
    ).html_safe
    link_for_download_attachment = link_to(
      t('review.survey.download_attachment'), review.file_model.file.url
    ).html_safe if review.file_model.try(:file?)

    out = "<b>#{Review.human_attribute_name(:survey)}</b>"

    out << " | #{link_for_download}" unless review.survey.blank?
    out << " | #{link_for_download_attachment}" if review.file_model.try(:file?)

    raw(out + simple_format(review.survey))
  end

  def link_to_suggested_process_control_findings(process_control)
    options = {
      title: t('review.suggested_findings_for', process_control: process_control.name),
      data:  { remote: true }
    }

    link_to suggested_process_control_findings_review_path(process_control.id), options do
      content_tag :span, nil, class: 'glyphicon glyphicon-eye-open'
    end
  end

  def review_scope_options
    REVIEW_SCOPES.map { |scope| [scope, scope] }
  end

  def review_risk_exposure_options
    REVIEW_RISK_EXPOSURE.map { |exposure| [exposure, exposure] }
  end

  def review_include_sox_options
    %w(yes no).map { |option| [t("label.#{option}"), option] }
  end
end
