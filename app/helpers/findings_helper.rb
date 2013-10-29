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

  def finding_repeated_of_label(form, readonly)
    if !form.object.new_record? && form.object.repeated_of && !readonly
      link = content_tag(:span,
        "[#{t('finding.undo_reiteration')}]",
        'data-help-dialog' => '#inline_undo_reiteration',
        :class => 'popup_link',
        :title => t('finding.undo_reiteration'),
        :style => 'color: #666666;'
      )

      form.label :repeated_of_id, raw(
        Finding.human_attribute_name('repeated_of_id') + ' ' +
        content_tag(:span, raw(link), :class => 'popup_link_container')
      ), :for => 'repeated_of_finding'
    else
      form.label :repeated_of_id
    end
  end

  def finding_repeated_of_if_field(form, readonly)
    if !form.object.new_record? && form.object.repeated_of
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
      if finding.stale?
        html_classes << 'strike'
      end

      if finding.rescheduled?
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

  def finding_updated_at_text(finding)
    label = Finding.human_attribute_name('updated_at')
    date = I18n.l(finding.updated_at, :format => :minimal) if finding.updated_at

    show_info "#{label}: #{date}"
  end

  def show_review_with_conclusion_status_as_abbr(review)
    review_data = review.has_final_review? ?
      t('review.with_final_review') : t('review.without_final_review')
    review_data << " | #{l(review.issue_date(true), :format => :long)}"

    content_tag(:abbr, h(review.identification), :title => review_data)
  end

  def show_finding_review_code_with_control_objective_as_abbr(finding)
    control_objective_text = "#{ControlObjectiveItem.model_name.human}: " +
      finding.control_objective_item.to_s

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
      link_to(
        image_tag(
          'clock.gif', :size => '11x11',
          :alt => t('finding.show_status_change_history'),
          :title => t('finding.show_status_change_history')
        ),
        '#', :onclick => "$('##{dom_id}').slideToggle();return false;", :class => :image_link
      ), :style => 'margin-left: .25em;'
    )
  end

  def finding_responsibles_list(finding)
    users = finding.users.map do |u|
      if finding.process_owners.include?(u)
        content_tag(:b, u.full_name_with_function +
            " | #{FindingUserAssignment.human_attribute_name(:process_owner)}")
      else
        u.full_name_with_function
      end
    end

    array_to_ul users, :class => :raw_list
  end

  def show_finding_answers_count(finding)
    finding_answers_count = finding.finding_answers.count
    user_answers = finding.finding_answers.where(:user_id => @auth_user.id).count
    klass = 'green' if user_answers > 0
    user_count = content_tag(
      :abbr, user_answers,
      :title => t('finding.user_finding_answers_count'),
      :class => klass
    )

    raw "#{finding_answers_count} / #{user_count}"
  end

  def show_finding_related_users
    users = []

    (@self_and_descendants + @related_users).each do |u|
      users << [
        u.full_name_with_function, {:user_id => u.id}.to_json
      ]

      unless u.can_act_as_audited?
        users << [
          "#{u.full_name_with_function} - #{t('activerecord.attributes.finding_user_assignment.responsible_auditor')}",
          {:user_id => u.id, :as_responsible => true}.to_json
        ]
      end
    end

    select nil, :user_id, sort_options_array(users), {:prompt => true},
      {:name => :user_id, :id => :user_id_select, :class => :inline_item}
  end

end
