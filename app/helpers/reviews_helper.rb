module ReviewsHelper
  def show_review_with_close_date_as_abbr(review)
    close_date = review.conclusion_final_review.try(:close_date)
    review_data = close_date ?
      t(:'review.review_data.close_date', :date => l(close_date, :format => :long)) :
      t(:'review.review_data.without_close_date')

    content_tag(:abbr, h(review.identification), :title => review_data)
  end

  def review_business_unit_type_text(review)
    review.plan_item.try(:business_unit).try(:business_unit_type).try(:name)
  end

  def review_business_unit_text(review)
    review.plan_item.try(:business_unit).try(:name)
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

    if procedure_control
      link_to t(:'review.view_procedure_control_for_the_period'),
        :remote => true, :update => 'procedure_control_data', :method => :get,
        :url => {:action => :procedure_control_data, :id => procedure_control},
        :loading => 'Helper.showLoading()', :complete => 'Helper.hideLoading()'
    else
      content_tag :span, t(:'review.view_procedure_control_for_the_period')
    end
  end
end