module FindingsHelper
  def finding_status_field form, disabled: false
    finding = form.object

    form.input :state,
      collection: finding_state_options_for(finding),
      label:      false,
      prompt:     true,
      input_html: {
        disabled: (disabled || finding.unconfirmed?),
        data: { weakness_state_changed_url: state_changed_weaknesses_path }
      }
  end

  def finding_repeated_of_label form, readonly:
    finding = form.object

    if finding.persisted? && finding.repeated_of && !readonly
      finding_repeated_of_label_editable form, finding
    else
      finding_repeated_of_label_readonly form, finding, readonly
    end
  end

  def finding_repeated_of_if_field form, readonly:
    finding = form.object

    if finding.persisted? && finding.repeated_of
      finding_repeated_of_input_readonly form, finding
    else
      finding_repeated_of_input_editable form, finding, readonly
    end
  end

  def finding_follow_up_date_text finding
    html_classes = []

    if finding.being_implemented? || finding.awaiting?
      html_classes << 'strike bg-danger' if finding.stale?
      html_classes << 'text-warning'     if finding.rescheduled?
      html_classes << 'text-success'     if html_classes.blank?
    end

    if finding.follow_up_date.present?
      date_text  = l finding.follow_up_date, format: :short
      html_class = html_classes.join(' ') if html_classes.any?

      content_tag :span, date_text, class: html_class
    end
  end

  def finding_updated_at_text finding
    text = Finding.human_attribute_name 'updated_at'
    date = l finding.updated_at, format: :minimal

    show_info "#{text}: #{date}"
  end

  def show_review_with_conclusion_status_as_abbr review
    review_data = if review.has_final_review?
                    "#{t 'review.with_final_review'} | #{summary_for review}"
                  else
                    t 'review.without_final_review'
                  end

    review_data << " | #{l review.issue_date(include_draft: true), format: :long}"

    content_tag :abbr, h(review.identification), title: review_data
  end

  def show_finding_review_code_with_decription_as_abbr finding
    content_tag :abbr, finding.review_code, title: j(finding.description)
  end

  def finding_answer_notification_check form
    html_class = @auth_user.can_act_as_audited? ? 'hidden' : nil
    label_text = html_class.blank? &&
      FindingAnswer.human_attribute_name('notify_users')

    form.input :notify_users,
      as:           :boolean,
      label:        false,
      inline_label: label_text,
      input_html:   { class: html_class }
  end

  def finding_show_status_change_history element_id
    icon = content_tag :span, nil, class: 'glyphicon glyphicon-time'

    link_to icon, "##{element_id}", {
      title: t('findings.form.show_status_change_history'),
      data:  { toggle: 'collapse' }
    }
  end

  def finding_responsibles_list finding
    owner_label = FindingUserAssignment.human_attribute_name 'process_owner'
    users       = finding.users.map do |user|
      if finding.process_owners.include?(user)
        content_tag :strong, "#{user.full_name_with_function} | #{owner_label}"
      else
        user.full_name_with_function
      end
    end

    array_to_ul users
  end

  def finding_work_paper_frozen? finding, work_paper
    code_prefix    = t 'code_prefixes.work_papers_in_weaknesses_follow_up'
    follow_up_code = work_paper.code =~ /\A#{code_prefix}\s\d+\z/

    !follow_up_code && finding.review&.is_frozen?
  end

  def show_finding_answers_count finding
    answers               = finding.finding_answers
    finding_answers_count = answers.count
    user_answers_count    = answers.where(user_id: @auth_user.id).count
    html_class            = 'text-success' if user_answers_count > 0
    user_count            = content_tag :abbr, user_answers_count, {
      title: t('.current_user_answers_count'),
      class: html_class
    }

    raw [finding_answers_count, user_count].join(' / ')
  end

  def show_finding_reading_warning finding
    readed_count  = finding.finding_answers.readed_by(@auth_user).count
    answers_count = finding.finding_answers.count

    if readed_count < answers_count
      title = t '.unread_answers', count: answers_count - readed_count

      content_tag(:span, class: 'text-warning', title: title) do
        content_tag :span, nil, class: 'glyphicon glyphicon-warning-sign'
      end
    end
  end

  def show_finding_related_users
    users = finding_current_user_related_user_options

    select nil, :user_id, sort_options_array(users),
      { prompt: true },
      { name: :user_id, id: :user_id_select, class: 'form-control' }
  end

  def finding_status_options
    Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).map do |k, v|
      [t("findings.state.#{k}"), v.to_s]
    end
  end

  def finding_fixed_status_options
    Finding::STATUS.slice(:implemented_audited, :assumed_risk, :expired).map do |k, v|
      [t("findings.state.#{k}"), v.to_s]
    end
  end

  def weaknesses_by_risk_and_business_unit_status_options
    exclude = %i(confirmed unconfirmed unanswered notify incomplete)

    Finding::STATUS.except(*exclude).map do |k, v|
      if Finding::PENDING_STATUS.include? v
        [t("findings.state.#{k}"), v.to_s]
      end
    end.compact
  end

  def finding_execution_status_options
    exclude = Finding::EXCLUDE_FROM_REPORTS_STATUS - [:unconfirmed, :confirmed]

    Finding::STATUS.except(*exclude).map do |k, v|
      [t("findings.state.#{k}"), v.to_s]
    end
  end

  def finding_status_options_by_action(action, params)
    case
    when action == :fixed_weaknesses_report
      finding_fixed_status_options
    when action == :weaknesses_by_risk_and_business_unit
      weaknesses_by_risk_and_business_unit_status_options
    when params[:execution].present?
      finding_execution_status_options
    else
      finding_status_options
    end
  end

  def show_commitment_date? finding_answer
    finding_answer.user.can_act_as_audited? &&
      finding_answer.requires_commitment_date? &&
      !current_organization.corporate?
  end

  def finding_description_label
    attr_name = @finding.class.human_attribute_name 'description'

    if SHOW_FINDING_CURRENT_SITUATION
      "#{attr_name} #{t '.origin'}"
    else
      attr_name
    end
  end

  def show_skip_work_paper_for finding
    state_errors = finding.errors.details[:state]

    finding.skip_work_paper ||
      state_errors.any? { |msg| msg[:error] == :must_have_a_work_paper }
  end

  def finding_task_status_options
    Task.statuses.map do |k, v|
      [t("tasks.status.#{k}"), k.to_s]
    end
  end

  def finding_tag_options
    Tag.list.for_findings.order(:name).map do |t|
      options = {
        data: {
          name:     t.name,
          readonly: TAGS_READONLY.include?(t.name)
        }
      }

      [t.name, t.id, options]
    end
  end

  def link_to_recode_tasks
    options = {
      class: 'pull-right',
      title: t('finding.recode_tasks'),
      data: {
        recode_tasks: true,
        confirm: t('messages.confirmation')
      }
    }

    link_to '#', options do
      content_tag :span, nil, class: 'glyphicon glyphicon-sort-by-order'
    end
  end

  def show_follow_up_timestamps?
    if @_show_follow_up_timestamps.nil?
      setting = current_organization.settings.find_by name: 'show_follow_up_timestamps'
      result  = (setting ? setting.value : DEFAULT_SETTINGS[:show_follow_up_timestamps][:value]) != '0'

      @_show_follow_up_timestamps = result
    else
      @_show_follow_up_timestamps
    end
  end

  private

    def finding_state_options_for finding
      statuses = finding_state_list_for finding
      excluded = []

      excluded << :repeated  unless finding.repeated?  || finding.was_repeated?
      excluded << :confirmed unless finding.confirmed? || finding.was_confirmed?

      options = statuses.except(*excluded).map do |k, v|
        [t("findings.state.#{k}"), v]
      end

      sort_options_array options
    end

    def finding_state_list_for finding
      statuses = finding.next_status_list

      if finding.errors[:state].present?
        state_was = if finding.new_record?
                      Finding::STATUS[:incomplete]
                    else
                      Finding.find(finding.id).state
                    end

        statuses.merge! finding.next_status_list(state_was)
      end

      statuses
    end

    def finding_repeated_of_label_editable form, finding
      link = finding_undo_reiteration_link finding
      text = raw(Finding.human_attribute_name('repeated_of_id') + ' | ' + link)

      form.label :repeated_of_id, text, for: 'repeated_of_finding'
    end

    def finding_repeated_of_label_readonly form, finding, readonly
      field = if readonly && finding.repeated_of.present?
                :repeated_of_finding
              else
                :repeated_of_id
              end

      form.label field, Finding.human_attribute_name(:repeated_of_id)
    end

    def finding_undo_reiteration_link finding
      url     = [:undo_reiteration, finding]
      options = {
        class: 'text-muted',
        data: {
          method:  :patch,
          confirm: t('messages.confirmation')
        }
      }

      link_to t('finding.undo_reiteration'), url, options
    end

    def finding_repeated_of_input_readonly form, finding
      form.input :repeated_of_finding, label: false, input_html: {
        id:       :repeated_of_finding,
        value:    finding.repeated_of,
        disabled: true
      }
    end

    def finding_repeated_of_input_editable form, finding, readonly
      review = finding.control_objective_item&.review
      fras   = Array(review&.finding_review_assignments).reject do |fra|
        fra.finding.repeated? || finding.class != fra.finding.class
      end

      form.input :repeated_of_id,
        collection: fras.map { |fra| [fra.finding, fra.finding_id] },
        prompt:     true,
        label:      false,
        input_html: {
          disabled: readonly,
          data:     {
            repeated_url: finding_repeated_of_generic_url_for(finding)
          }
        }
    end

    def finding_repeated_of_generic_url_for finding
      url_for controller: finding.class.to_s.tableize,
              action:     :show,
              id:         '[FINDING_ID]'
    end

    def finding_current_user_related_user_options
      related     = @self_and_descendants + @related_users
      owner       = FindingUserAssignment.human_attribute_name 'process_owner'
      responsible = FindingUserAssignment.human_attribute_name 'responsible_auditor'

      related.each_with_object([]) do |user, users|
        options                = { user_id: user.id }
        role_label, new_option = if user.can_act_as_audited?
                                  [owner, :as_owner]
                                else
                                  [responsible, :as_responsible]
                                end

        users << [user.full_name_with_function, options.to_json]
        users << [
          "#{user.full_name_with_function} - #{role_label}",
          options.merge(new_option => true).to_json
        ]
      end
    end

    def summary_for review
      summary = review.conclusion_final_review.summary || '-'

      "#{ConclusionReview.human_attribute_name 'summary'}: #{summary}"
    end
end
