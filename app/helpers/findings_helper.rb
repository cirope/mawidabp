module FindingsHelper
  def finding_status_field(form, inline = true, disabled = false)
    finding = form.object
    statuses = finding.repeated? ?
      finding.next_status_list : finding.next_status_list.except(:repeated)
    options = statuses.map { |k, v| [t(:"finding.status_#{k}"), v] }

    form.select :state, sort_options_array(options),
      {:prompt => true},
      {:class => (:inline_item if inline),
      :disabled => (disabled || finding.unconfirmed?)}
  end

  def finding_repeated_of_if_field(form, readonly)
    if form.object.repeated_of
      text_field_tag :repeated_of_finding, form.object.repeated_of, :disabled => true
    else
      review = form.object.control_objective_item.try(:review)
      fras = (review.try(:finding_review_assignments) || []).reject do |fra|
        fra.finding.repeated?
      end
      findings = fras.map { |fra| [fra.finding, fra.finding_id.to_i] }
      
      form.select :repeated_of_id, findings, {:prompt => true},
        {:disabled => readonly}
    end
  end

  def finding_follow_up_date_text(finding)
    html_classes = []

    if finding.being_implemented?
      if finding.kind_of?(Weakness) && finding.stale?
        html_classes << 'strike'
      end

      if finding.kind_of?(Weakness) && finding.rescheduled?
        html_classes << 'yellow'
      end

      html_classes << 'green' if html_classes.blank?
    end

    unless finding.follow_up_date.blank?
      content_tag(:span, l(finding.follow_up_date, :format => :short),
        :class => (html_classes.join(' ') unless html_classes.blank?))
    else
      ''
    end
  end

  def show_review_with_conclusion_status_as_abbr(review)
    review_data = review.has_final_review? ?
      t(:'review.with_final_review') : t(:'review.without_final_review')
    review_data << " | #{l(review.issue_date(true), :format => :long)}"

    content_tag(:abbr, h(review.identification), :title => review_data)
  end

  def show_finding_review_code_with_control_objective_as_abbr(finding)
    control_objective_text = "#{ControlObjectiveItem.model_name.human}: " +
      finding.control_objective_item.control_objective_text

    content_tag(:abbr, h(finding.review_code), :title => control_objective_text)
  end


  def finding_answer_notification_check(form)
    label_and_check = [
      form.label(:notify_users, nil, :class => :plain_label),
      show_inline_help_for(:finding_answer_notification,
        'finding_answer_notification_NEW_RECORD'),
      form.check_box(:notify_users, :style => 'margin: 0em 0em 0em 1em;')
    ]

    raw label_and_check.map {|tag| content_tag(:span, tag)}.join
  end

  def finding_show_status_change_history(dom_id)
    content_tag(:span,
      link_to_function(
        image_tag(
          'clock.gif', :size => '11x11',
          :alt => t(:'finding.show_status_change_history'),
          :title => t(:'finding.show_status_change_history')
        ),
        "Element.showOrHide('#{dom_id}')", :class => :image_link
      ), :style => 'margin-left: .25em;'
    )
  end
end