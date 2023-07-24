module FindingsHelper
  def finding_status_field form, disabled: false, options_html: {}
    finding = form.object

    form.input :state,
      collection: finding_state_options_for(finding),
      label:      false,
      prompt:     true,
      input_html: {
        disabled: (disabled || finding.unconfirmed?)
      }.merge(options_html)
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

  def next_task_expiration finding
    next_expiration = finding.next_task_expiration

    if next_expiration.present?
      next_expiration_text = " / #{l finding.next_task_expiration, format: :short}"
      html_class           = (next_expiration < Date.today ? 'strike bg-danger' : 'text-success')

      content_tag :span, next_expiration_text, class: html_class
    else
      ''
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

    content_tag :abbr, h(super_truncate(review.identification, 15)), title: review_data
  end

  def show_finding_review_code_with_decription_as_abbr finding
    content_tag :abbr, finding.review_code, title: j(finding.description)
  end

  def finding_answer_notification_check form, finding_answer
    form.input :notify_users,
      as:           :boolean,
      wrapper_html: { hidden: @auth_user.can_act_as_audited? || bic_committee?(finding_answer) }
  end

  def bic_committee? finding_answer
    finding_answer.user.committee? && Current.conclusion_pdf_format == 'bic'
  end

  def finding_show_status_change_history element_id
    link_to icon('fas', 'history'), "##{element_id}", {
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

    array_to_ul users, class: 'mb-1'
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
        icon 'fas', 'exclamation-triangle'
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
    slice  = [:implemented_audited, :expired]
    slice |= [:assumed_risk] unless HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK

    Finding::STATUS.slice(*slice).map do |k, v|
      [t("findings.state.#{k}"), v.to_s]
    end
  end

  def finding_execution_status_options
    exclude = Finding::EXCLUDE_FROM_REPORTS_STATUS - [:unconfirmed, :confirmed, :notify, :incomplete]

    Finding::STATUS.except(*exclude).map do |k, v|
      [t("findings.state.#{k}"), v.to_s]
    end
  end

  def finding_status_options_by_action(action, params)
    case
    when action == :fixed_weaknesses_report
      finding_fixed_status_options
    when params[:execution].present?
      finding_execution_status_options
    else
      finding_status_options
    end
  end

  def show_commitment_date? finding_answer
    finding_answer.commitment_date.present? || (
      finding_answer.user.can_act_as_audited?  &&
      finding_answer.requires_commitment_date? &&
      !current_organization.corporate?
    ) || bic_committee?(finding_answer)
  end

  def show_commitment_endorsement_edition? finding_answer
    !@auth_user.can_act_as_audited? && finding_answer.finding.being_implemented?
  end

  def finding_endorsement_class endorsement
    if endorsement.pending?
      'secondary'
    elsif endorsement.approved?
      'success'
    else
      'danger'
    end
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
    Tag.list.for_findings.where(obsolete: false).order(:name).map do |t|
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
      class: 'float-right',
      title: t('finding.recode_tasks'),
      data: {
        recode_tasks: true,
        confirm: t('messages.confirmation')
      }
    }

    link_to '#', options do
      icon 'fas', 'sort-numeric-down'
    end
  end

  def link_to_create_work_paper finding_answer
    if action_name == 'edit' && !@auth_user.can_act_as_audited?
      path    = finding_work_papers_path finding_id:        @finding,
                                         finding_answer_id: finding_answer
      options = {
        class: 'btn btn-outline-secondary',
        title: t('finding.create_work_paper'),
        data: {
          add_param: 'last_work_paper_code',
          method:    :post,
          remote:    true,
          confirm:   t('messages.confirmation')
        }
      }

      link_to icon('fas', 'paperclip'), path, options
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

  def disabled_priority finding, readonly
    if SHOW_CONDENSED_PRIORITIES
      readonly || finding.risk != Finding.risks[:medium]
    else
      readonly
    end
  end

  def finding_answer_rows
    if SHOW_FINDING_CURRENT_SITUATION && USE_SCOPE_CYCLE
      7
    elsif SHOW_FINDING_CURRENT_SITUATION
      9
    else
      5
    end
  end

  def extension_enabled? finding
    finding.review.conclusion_final_review.blank? || finding.extension
  end

  def data_for_submit finding
    if USE_SCOPE_CYCLE
      {
        data: {
          confirm_message: I18n.t('findings.form.confirm_finding_without_extension',
                                  extension: Finding.human_attribute_name(:extension)),
          checkbox_target: '#finding_extension',
          target_value_checkbox: false,
          states_target: Finding.states_that_allow_extension,
          input_with_state: '#finding_state',
          condition_to_receive_confirm: finding.review.conclusion_final_review.present? && finding.extension
        }
      }
    else
      {}
    end
  end

  def finding_has_issues? finding
    USE_SCOPE_CYCLE ? finding.issues.any? : false
  end

  def data_options_for_suggested_follow_up_date type_form
    if USE_SCOPE_CYCLE
      {
        target_input_with_origination_date: "##{type_form}_origination_date",
        target_input_with_risk: "##{type_form}_risk",
        target_input_with_state: "##{type_form}_state",
        target_values_states_change_label: Finding.states_that_suggest_follow_up_date,
        days_to_add: Finding.suggestion_to_add_days_follow_up_date_depending_on_the_risk.to_json,
        suffix: I18n.t('findings.form.follow_up_date_label_append'),
        target_input_with_label: "##{type_form}_follow_up_date"
      }
    else
      {}
    end
  end

  def link_to_edit_finding finding, auth_user
    if !auth_user.can_act_as_audited? || finding.users.reload.include?(auth_user)
      if finding.pending?
        link_to_edit(edit_finding_path('incomplete', finding, user_id: params[:user_id]))
      elsif !finding.repeated? && %w(bic).include?(Current.conclusion_pdf_format)
        link_to_edit(edit_bic_sigen_fields_finding_path('complete', finding))
      elsif %w(nbc).include?(Current.conclusion_pdf_format)
        link_to_edit(edit_finding_path('complete', finding, user_id: params[:user_id]))
      end
    end
  end

  def translate_filter_columns columns
    translated_columns = {
      'organization' => Finding.human_attribute_name('organization'),
      'review'       => Review.model_name.human,
      'project'      => PlanItem.human_attribute_name('project'),
      'review_code'  => Finding.human_attribute_name('review_code'),
      'title'        => Finding.human_attribute_name('title'),
      'updated_at'   => Finding.human_attribute_name('updated_at'),
      'tags'         => Tag.model_name.human(count: 0)
    }

    columns.map { |c| translated_columns[c] }.compact.to_sentence
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

    def finding_impact_risks_types finding
      finding.amount_by_impact.invert.reverse_each.to_json
    end

    def finding_percentage_impact_risks_types finding
      finding.percentage_by_impact.invert.reverse_each.to_json
    end

    def finding_probability_risks_types finding
      finding.percentage_by_probability.invert.reverse_each.to_json
    end

    def finding_bic_risks_types finding
      finding.bic_risks_types.invert.reverse_each.to_json
    end
end
