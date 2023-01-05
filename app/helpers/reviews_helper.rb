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
      :plan_items, :name, :id, :project_with_dates, {:prompt => true},
      {:class => 'form-control', :disabled => readonly}
  end

  def review_business_unit_type_text(review)
    review.plan_item.try(:business_unit).try(:business_unit_type).try(:name)
  end

  def review_business_unit_text(review)
    review.plan_item.try(:business_unit).try(:name)
  end

  def review_business_unit_types
    if @review&.business_unit_type
      BusinessUnitType.list.where.not(id: @review.business_unit_type.id).order :name
    else
      BusinessUnitType.list.order :name
    end
  end

  def review_business_unit_type_prefixes
    BusinessUnitType.list.map do |but|
      [
        but.review_prefix,
        but.review_prefix,
        {
          data: { use_prefix: but.independent_identification }
        }
      ]
    end
  end

  def user_assignment_type_field(form, inline = true, disabled = false)
    input_options = { disabled: disabled, data: { review_role: true } }
    options = user_assignment_type_options_for form.object.user

    form.input :assignment_type, collection: options, prompt: true,
      label: false, input_html: input_options
  end

  def user_assignment_type_options_for(user, include_blank: false)
    options = Array(user&.review_assignment_options).map do |k, v|
      [t("review.user_assignment.type_#{k}"), v]
    end

    if include_blank && options.size > 1
      [[t('helpers.select.prompt'), '']] + options
    else
      options
    end
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
    )

    out = "<b>#{Review.human_attribute_name(:survey)}</b>"

    out << " | #{link_for_download}" unless review.survey.blank?
    out << "<ul>"

    review.file_models.each do |fm|
      link_for_download_attachment = link_to(
        fm.file_file_name, fm.file.url
      )

      out << "<li>#{link_for_download_attachment}</li>"
    end

    out << "</ul>"

    raw(out + simple_format(review.survey, class: 'mb-1'))
  end

  def link_to_suggested_process_control_findings(process_control)
    options = {
      title: t('review.suggested_findings_for', process_control: process_control.name),
      data:  { remote: true }
    }

    link_to suggested_process_control_findings_review_path(process_control.id), options do
      icon 'fas', 'eye'
    end
  end

  def review_scope_options
    REVIEW_SCOPES.keys
  end

  def review_risk_exposure_options
    REVIEW_RISK_EXPOSURE.map { |exposure| [exposure, exposure] }
  end

  def review_include_sox_options
    %w(yes no).map { |option| [t("label.#{option}"), option] }
  end

  def review_control_objective_class(control_objective_item)
    html_classes = []

    if control_objective_item.finished
      html_classes << 'strike'
      html_classes << 'text-muted'
    end

    if control_objective_item.exclude_from_score
      highest_relevance = control_objective_item.relevance ==
        ControlObjectiveItem.relevances_values.last

      html_classes << (highest_relevance ? 'bg-danger' : 'bg-warning')
    end

    html_classes.join(' ')
  end

  def review_year_suffixes
    year  = Time.zone.today.year
    years = []

    years << year.pred if Time.zone.today.month <= 2
    years << year
    years << year.next if Time.zone.today.month >= 10

    years
  end

  def show_review_finished_work_papers_icon review
    wrapper_class = if review.work_papers_revised?
                      'text-success'
                    elsif review.work_papers_finished? && review.is_frozen?
                      'text-danger'
                    end

    if review.work_papers_finished? || review.work_papers_revised?
      content_tag(:span, class: wrapper_class) do
        icon 'fas', 'paperclip', title: t('review.work_papers_marked_as_finished')
      end
    end
  end

  def audit_team_for review
    audit_team = review.review_user_assignments.reload.select &:in_audit_team?

    ActiveSupport::SafeBuffer.new.tap do |buffer|
      audit_team.each do |rua|
        buffer << content_tag(:span, class: 'text-muted') do
          icon 'fas', 'user', title: rua.user.full_name
        end

        buffer << ' '
      end
    end
  end

  def link_to_excluded_control_objectives
    path    = excluded_control_objectives_review_path @review
    options = {
      title: t('review.show_excluded_control_objectives'),
      data:  { remote: true }
    }

    link_to icon('fas', 'cut'), path, options
  end

  def excluded_control_objective_class control_objective
    if control_objective.obsolete
      'bg-info'
    elsif control_objective.relevance == ControlObjective.relevances_values.last
      'bg-danger'
    else
      'bg-warning'
    end
  end

  def link_to_recover_original_control_objective_name(control_objective_item)
    icon = content_tag(
      :span,
      icon('fas', 'exclamation-triangle'),
      class: 'text-warning'
    )

    link_to(
      icon,
      reset_control_objective_name_review_path(
        control_objective_item.review.id, control_objective_item_id: control_objective_item.id
      ),
      title: t('review.outdated_control_objective_name'),
      data:  {
        remote:  true,
        method:  :patch,
        confirm: t('messages.confirmation'),
        reset_name_for: control_objective_item.id
      }
    )
  end

  def count_control_objective_items_by_finished_status review, finished: false
    review.control_objective_items.select { |coi| coi.finished == finished }.count
  end

  def type_review
    Review::TYPES_REVIEW.map do |key, value|
      [t("reviews.form.#{key}"), value]
    end
  end

  def show_external_review_options review
    Review.list.map { |r| [r.identification, r.id] if r.conclusion_final_review }.compact
  end

  def subsidiaries_options
    Subsidiary.list.map { |s| [s.to_s, s.id] }
  end
end
