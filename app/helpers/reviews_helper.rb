module ReviewsHelper
  def show_review_with_close_date_as_acronym(review)
    close_date = review.conclusion_final_review.try(:close_date)
    review_data = close_date ?
      t(:'review.review_data.close_date', :date => l(close_date, :format => :long)) :
      t(:'review.review_data.without_close_date')

    content_tag(:acronym, h(review.identification), :title => review_data)
  end

  def review_business_unit_type_text(review)
    review.plan_item && review.plan_item.business_unit ?
      t("organization.business_unit_#{
        review.plan_item.business_unit.type}.type") : nil
  end

  def review_business_unit_text(review)
    review.plan_item && review.plan_item.business_unit ?
      review.plan_item.business_unit.name : nil
  end

  def user_assignment_type_field(form, inline = true, disabled = false)
    options = ReviewUserAssignment::TYPES.map do |k, v|
      [t("review.user_assignment.type_#{k}"), v]
    end

    form.select :assignment_type, sort_options_array(options),
      {:prompt => true},
      {:class => (:inline_item if inline), :disabled => disabled}
  end

  def user_assignment_type_text(type)
    content_tag(:span, user_assignment_type_name_for(type), :class => :bold)
  end

  def user_assignment_type_name_for(type)
    t "review.user_assignment.type_#{ReviewUserAssignment::TYPES.invert[type]}"
  end

  def next_review_work_paper_code(review)
    code_prefix = parameter_in(@auth_organization.id,
      :admin_code_prefix_for_work_papers_in_control_objectives,
      review.try(:created_at))

    review ? review.last_control_objective_work_paper_code(code_prefix) :
      "#{code_prefix} 0".strip
  end

  def link_to_procedure_control_for_review(review)
    procedure_control = ProcedureControl.list_by_period(review.period_id).first

    link_to_unless(procedure_control.nil?,
      t(:'review.view_procedure_control_for_the_period'),
      procedure_control ? procedure_control_path(procedure_control) : nil)
  end
end