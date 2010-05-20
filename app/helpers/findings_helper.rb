module FindingsHelper
  def finding_status_field(form, inline = true, disabled = false)
    finding = form.object
    options = finding.next_status_list.map do |k, v|
      [t("finding.status_#{k}"), v]
    end

    form.select :state, sort_options_array(options),
      {:prompt => true},
      {:class => (:inline_item if inline),
      :disabled => (disabled || finding.unconfirmed?)}
  end

  def finding_follow_up_date_text(finding)
    html_classes = []

    if finding.kind_of?(Weakness) && finding.stale?
      html_classes << 'strike'
    end

    if finding.kind_of?(Weakness) && finding.rescheduled?
      html_classes << 'yellow'
    end
    
    html_classes << 'green' if finding.being_implemented? && html_classes.blank?

    unless finding.follow_up_date.blank?
      content_tag(:span, l(finding.follow_up_date, :format => :short),
        :class => (html_classes.join(' ') unless html_classes.blank?))
    else
      ''
    end
  end

  def show_review_with_conclusion_status_as_acronym(review)
    review_data = review.has_final_review? ?
      t(:'review.with_final_review') : t(:'review.without_final_review')

    content_tag(:acronym, h(review.identification), :title => review_data)
  end

  def show_finding_review_code_with_control_objective_as_acronym(finding)
    control_objective_text = "#{ControlObjectiveItem.human_name}: " +
      finding.control_objective_item.control_objective_text

    content_tag(:acronym, h(finding.review_code), :title => control_objective_text)
  end


  def finding_answer_notification_check(form)
    unless @auth_user.audited?
      label_and_check = [
        form.label(:notify_users, nil, :class => :plain_label),
        show_inline_help_for(:finding_answer_notification,
          'finding_answer_notification_NEW_RECORD'),
        form.check_box(:notify_users, :style => 'margin: 0em 0em 0em 1em;')
      ]

      label_and_check.map {|tag| content_tag(:span, tag)}.join
    end
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