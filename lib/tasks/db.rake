namespace :db do
  desc 'Put records, remove and update the database using current app values'
  task update: :environment do
    ActiveRecord::Base.transaction do
      update_organization_settings               # 2017-03-15 last 2021-08-09
      add_new_answer_options                     # 2017-06-29
      add_best_practice_privilege                # 2018-01-31
      add_control_objective_privilege            # 2018-01-31
      add_task_codes                             # 2018-07-24
      mark_tasks_as_finished                     # 2019-01-04
      update_finding_first_follow_up_date        # 2019-01-07
      reset_notification_level                   # 2019-03-06
      update_finding_reschedule_count            # 2019-07-19
      complete_main_recommendations              # 2019-07-23
      update_tag_style                           # 2019-09-26
      update_tag_icons                           # 2019-09-30
      update_finding_state_dates                 # 2020-01-16
      update_finding_parent_ids                  # 2020-01-22
      collapse_extended_risks                    # 2020-02-04
      #remove_finding_awaiting_state             # 2020-02-05
      add_repeated_findings_privilege            # 2020-02-07
      update_latest_on_findings                  # 2020-02-08
      update_review_scopes                       # 2020-02-20
      fix_final_latest_findings                  # 2020-03-13
      fix_email_organization                     # 2020-04-24
      add_follow_up_audited_privilege            # 2020-05-08
      add_file_model_review                      # 2020-07-20
      remove_auditor_junior_role                 # 2020-11-04
      add_commitment_data_on_findings            # 2020-12-01
      update_finding_follow_up_date_last_changed # 2021-12-22
      update_draft_review_code                   # 2022-07-20
      update_options_tags                        # 2023-06-05
      update_roles_identifier                    # 2023-07-24
      update_status_work_papers                  # 2023-09-25
      update_risk_assessments_changes            # 2023-10-02
    end
  end
end

private

  def update_organization_settings
    if add_show_print_date_on_pdfs? # 2017-03-15
      Organization.all.each do |o|
        o.settings.create! name:        'show_print_date_on_pdfs',
                           value:       DEFAULT_SETTINGS[:show_print_date_on_pdfs][:value],
                           description: I18n.t('settings.show_print_date_on_pdfs')
      end
    end

    if add_brief_period_in_weeks? # 2018-08-14
      Organization.all.each do |o|
        o.settings.create! name:        'brief_period_in_weeks',
                           value:       DEFAULT_SETTINGS[:brief_period_in_weeks][:value],
                           description: I18n.t('settings.brief_period_in_weeks')
      end
    end

    if add_show_follow_up_timestamps? # 2018-10-28
      Organization.all.each do |o|
        o.settings.create! name:        'show_follow_up_timestamps',
                           value:       DEFAULT_SETTINGS[:show_follow_up_timestamps][:value],
                           description: I18n.t('settings.show_follow_up_timestamps')
      end
    end

    if add_require_manager_on_findings? # 2018-11-09
      Organization.all.each do |o|
        o.settings.create! name:        'require_manager_on_findings',
                           value:       DEFAULT_SETTINGS[:require_manager_on_findings][:value],
                           description: I18n.t('settings.require_manager_on_findings')
      end
    end

    if add_hide_import_from_ldap? # 2020-01-02
      Organization.all.each do |o|
        o.settings.create! name:        'hide_import_from_ldap',
                           value:       DEFAULT_SETTINGS[:hide_import_from_ldap][:value],
                           description: I18n.t('settings.hide_import_from_ldap')
      end
    end

    if add_skip_function_and_manager_from_ldap_sync? # 2020-01-02
      Organization.all.each do |o|
        o.settings.create! name:        'skip_function_and_manager_from_ldap_sync',
                           value:       DEFAULT_SETTINGS[:skip_function_and_manager_from_ldap_sync][:value],
                           description: I18n.t('settings.skip_function_and_manager_from_ldap_sync')
      end
    end

    if add_hide_obsolete_best_practices? # 2020-10-19
      Organization.all.find_each do |o|
        o.settings.create! name:        'hide_obsolete_best_practices',
                           value:       DEFAULT_SETTINGS[:hide_obsolete_best_practices][:value],
                           description: I18n.t('settings.hide_obsolete_best_practices')
      end
    end

    if set_hours_of_work_per_day? # 2021-04-30
      Organization.all.find_each do |o|
        o.settings.create! name:        'hours_of_work_per_day',
                           value:       DEFAULT_SETTINGS[:hours_of_work_per_day][:value],
                           description: I18n.t('settings.hours_of_work_per_day')
      end
    end

    if set_conclusion_review_receiver? # 2021-08-09
      Organization.all.find_each do |o|
        o.settings.create! name:        'conclusion_review_receiver',
                           value:       DEFAULT_SETTINGS[:conclusion_review_receiver][:value],
                           description: I18n.t('settings.conclusion_review_receiver')
      end
    end

    if add_temporary_polls? # 2023-02-01
      Organization.all.find_each do |o|
        o.settings.create! name:        'temporary_polls',
                           value:       DEFAULT_SETTINGS[:temporary_polls][:value],
                           description: I18n.t('settings.temporary_polls')
      end
    end

    if add_finding_warning_expire_days? #2023-06-06
      Organization.all.find_each do |o|
        o.settings.create! name:        'finding_warning_expire_days',
                           value:       DEFAULT_SETTINGS[:finding_warning_expire_days][:value],
                           description: I18n.t('settings.finding_warning_expire_days')
      end
    end
  end

  def set_conclusion_review_receiver?
    USE_SCOPE_CYCLE && Setting.where(name: 'conclusion_review_receiver').empty?
  end

  def set_hours_of_work_per_day?
    Setting.where(name: 'hours_of_work_per_day').empty?
  end

  def add_hide_obsolete_best_practices?
    Setting.where(name: 'hide_obsolete_best_practices').empty?
  end

  def add_skip_function_and_manager_from_ldap_sync?
    Setting.where(name: 'skip_function_and_manager_from_ldap_sync').empty?
  end

  def add_hide_import_from_ldap?
    Setting.where(name: 'hide_import_from_ldap').empty?
  end

  def add_require_manager_on_findings?
    Setting.where(name: 'require_manager_on_findings').empty?
  end

  def add_show_follow_up_timestamps?
    Setting.where(name: 'show_follow_up_timestamps').empty?
  end

  def add_show_print_date_on_pdfs?
    Setting.where(name: 'show_print_date_on_pdfs').empty?
  end

  def add_brief_period_in_weeks?
    Setting.where(name: 'brief_period_in_weeks').empty?
  end

  def add_temporary_polls?
    Setting.where(name: 'temporary_polls').empty?
  end

  def add_finding_warning_expire_days?
    Setting.where(name: 'finding_warning_expire_days').empty?
  end

  def add_new_answer_options
    if add_new_answer_options?
      Question.where(answer_type: Question::ANSWER_TYPES[:multi_choice]).each do |q|
        q.answer_options.create! option: 'not_apply'
      end
    end
  end

  def add_new_answer_options?
    AnswerOption.where(option: 'not_apply').empty?
  end

  def add_best_practice_privilege
    if add_best_practice_privilege?
      Privilege.where(module: 'administration_best_practices').find_each do |p|
        attrs = p.attributes.
          except('id', 'module', 'created_at', 'updated_at').
          merge(module: 'administration_best_practices_best_practices')

        Privilege.create! attrs
      end
    end
  end

  def add_best_practice_privilege?
    Privilege.where(module: 'administration_best_practices_best_practices').empty?
  end

  def add_control_objective_privilege
    if add_control_objective_privilege?
      Privilege.where(module: 'administration_best_practices_best_practices').find_each do |p|
        attrs = p.attributes.
          except('id', 'module', 'created_at', 'updated_at').
          merge(module: 'administration_best_practices_control_objectives')

        Privilege.create! attrs
      end
    end
  end

  def add_control_objective_privilege?
    Privilege.where(module: 'administration_best_practices_control_objectives').empty?
  end

  def add_task_codes
    if add_task_codes?
      last_finding = nil
      count = 0

      Task.where(code: nil).order(finding_id: :asc, due_on: :asc).each do |t|
        if last_finding != t.finding_id
          last_finding = t.finding_id
          count = 0
        end

        t.update_column :code, '%02d' % (count += 1)
      end
    end
  end

  def add_task_codes?
    Task.where(code: nil).any?
  end

  def update_finding_reschedule_count
    if update_finding_reschedule_count?
      Finding.where(reschedule_count: 0).find_each do |finding|
        count = finding.calculate_reschedule_count

        finding.update_column :reschedule_count, count if count > 0
      end
    end
  end

  def update_finding_reschedule_count?
    Finding.where.not(reschedule_count: 0).empty?
  end

  def mark_tasks_as_finished
    if mark_tasks_as_finished?
      repeated_findings_with_unfinished_tasks.each do |finding|
        finding.tasks.each &:finished!
      end
    end
  end

  def mark_tasks_as_finished?
    repeated_findings_with_unfinished_tasks.any?
  end

  def repeated_findings_with_unfinished_tasks
    pending_tasks = Task.pending.or Task.in_progress

    Finding.
      repeated.
      includes(:tasks).
      references(:tasks).
      merge pending_tasks
  end

  def update_finding_first_follow_up_date
    if update_finding_first_follow_up_date?
      findings = Finding.
        where(first_follow_up_date: nil).
        where.not follow_up_date: nil

      findings.each do |finding|
        first_follow_up_date = finding.first_follow_up_date_on_versions

        finding.update_column :first_follow_up_date, first_follow_up_date
      end
    end
  end

  def update_finding_first_follow_up_date?
    Finding.
      where(first_follow_up_date: nil).
      where.not(follow_up_date: nil).exists?
  end

  def reset_notification_level
    if reset_notification_level?
      findings_for_notification_level_reset.update_all notification_level: 0
    end
  end

  def reset_notification_level?
    Finding.where(last_notification_date: nil).count == Finding.count
  end

  def findings_for_notification_level_reset
    pending_statuses = [Finding::STATUS[:being_implemented]]

    Finding.
      finals(false).
      where(state: pending_statuses).
      where.not notification_level: 0
  end

  def complete_main_recommendations
    if complete_main_recommendations?
      SHOW_CONCLUSION_ALTERNATIVE_PDF.each do |prefix, format|
        if format == 'bic'
          organization         = Organization.find_by! prefix: prefix
          Current.organization = organization
          Current.group        = organization.group

          ConclusionReview.list.where(main_recommendations: nil).each do |cr|
            review = cr.review
            result = []

            review.grouped_control_objective_items.each do |process_control, cois|
              cois.sort.each do |coi|
                coi.weaknesses.not_revoked.sort_for_review.each do |w|
                  if w.audit_recommendations.present?
                    result << w.audit_recommendations.strip
                  end
                end
              end
            end

            cr.update_column :main_recommendations, result.join("\r\n\r\n")
          end
        end
      end

      Current.organization = nil
      Current.group        = nil
    end
  end

  def complete_main_recommendations?
    has_format = SHOW_CONCLUSION_ALTERNATIVE_PDF.values.any? { |v| v == 'bic' }

    has_format && ConclusionReview.where.not(main_recommendations: nil).empty?
  end

  def update_tag_style
    if update_tag_style?
      Tag.where(style: 'default').update_all style: 'secondary'
    end
  end

  def update_tag_style?
    Tag.where(style: 'default').any?
  end

  ICON_EQUIVALENCE = {
    'alert'            => 'exclamation-triangle',
    'ban-circle'       => 'ban',
    'cd'               => 'compact-disc',
    'compressed'       => 'compress',
    'exclamation-sign' => 'exclamation-circle',
    'facetime-video'   => 'video',
    'fire'             => 'fire-alt',
    'flash'            => 'bolt',
    'folder-close'     => 'folder',
    'info-sign'        => 'info-circle',
    'phone-alt'        => 'phone',
    'picture'          => 'image',
    'pushpin'          => 'thumbtack',
    'question-sign'    => 'question-circle',
    'stats'            => 'chart-bar',
    'tree-deciduous'   => 'tree',
    'warning-sign'     => 'exclamation-triangle'
  }

  def update_tag_icons
    if update_tag_icons?
      Tag.where(icon: ICON_EQUIVALENCE.keys).each do |tag|
        tag.update_column :icon, ICON_EQUIVALENCE[tag.icon]
      end
    end
  end

  def update_tag_icons?
    Tag.where(icon: ICON_EQUIVALENCE.keys).any?
  end

  def update_finding_state_dates
    if update_finding_state_dates?
      Finding.implemented.find_each do |f|
        f.update_column :implemented_at, f.version_implemented_at
      end

      Finding.where(state: Finding::FINAL_STATUS).find_each do |f|
        f.update_column :implemented_at, f.version_implemented_at
        f.update_column :closed_at,      f.version_closed_at
      end
    end
  end

  def update_finding_parent_ids
    if update_finding_parent_ids?
      Finding.with_repeated.finals(false).find_each do |finding|
        parent_ids = []
        cursor     = finding

        while cursor.repeated_of
          parent_ids << (cursor = cursor.repeated_of).id
        end

        finding.update_column :parent_ids, parent_ids.reverse
      end
    end
  end

  def update_finding_state_dates?
    Finding.where.not(implemented_at: nil).empty? &&
      Finding.where.not(closed_at: nil).empty?
  end

  def update_finding_parent_ids?
    POSTGRESQL_ADAPTER && Finding.where("#{Finding.table_name}.parent_ids != '{}'").empty?
  end

  def collapse_extended_risks
    if collapse_extended_risks?
      swaps = {
        0 => { risk: 0, priority: 0 },
        1 => { risk: 0, priority: 0 },
        2 => { risk: 1, priority: 0 },
        3 => { risk: 1, priority: 2 },
        4 => { risk: 2, priority: 0 },
        5 => { risk: 2, priority: 0 }
      }

      swaps.each do |risk, new_attributes|
        Finding.where(risk: risk).find_each do |finding|
          finding.update_columns new_attributes

          finding.versions.each do |version|
            object         = version.object
            object_changes = version.object_changes

            if (v_risk = object && object['risk'])
              new_values = swaps[v_risk]

              object['risk']     = new_values[:risk]
              object['priority'] = new_values[:priority]
            end

            if (v_risks = object_changes && object_changes['risk'])
              object_changes['risk'] = v_risks.map do |v_risk|
                v_risk && swaps[v_risk][:risk]
              end

              if v_risks.last == 3
                prev = v_risks.first.nil? ? nil : 0

                object_changes['priority'] = [prev, swaps[3][:priority]]
              elsif v_risks.first == 3
                object_changes['priority'] = [swaps[3][:priority], 0]
              end
            end

            version.update_columns object: object, object_changes: object_changes
          end
        end
      end
    end
  end

  def collapse_extended_risks?
    ENV['SHOW_EXTENDED_RISKS'] == 'true' && Finding.where(risk: [3, 4, 5]).any?
  end

  def remove_finding_awaiting_state
    if remove_finding_awaiting_state?
      old_state   = -4
      replacement = Finding::STATUS[:being_implemented]

      Finding.where(state: old_state).update_all state: replacement

      Finding.find_each do |finding|
        finding.versions.each do |version|
          object         = version.object
          object_changes = version.object_changes

          if (v_state = object && object['state']) && v_state == old_state
            object['state'] = replacement
          end

          if (v_states = object_changes && object_changes['state'])
            object_changes['state'] = v_states.map do |v_state|
              v_state == old_state ? replacement : v_state
            end

            if object_changes['state'].uniq.size == 1
              object_changes.delete 'state'
            end
          end

          object.delete         'progress' if object
          object_changes.delete 'progress' if object_changes

          version.update_columns object: object, object_changes: object_changes
        end
      end
    end
  end

  def remove_finding_awaiting_state?
    Finding.where(state: -4).any?
  end

  def add_repeated_findings_privilege
    if repeated_findings_privilege?
      Privilege.where(module: 'follow_up_complete_findings').find_each do |p|
        attrs = p.attributes.
          except('id', 'module', 'created_at', 'updated_at').
          merge(module: 'follow_up_repeated_findings')

        Privilege.create! attrs
      end
    end
  end

  def repeated_findings_privilege?
    Privilege.where(module: 'follow_up_repeated_findings').empty?
  end

  def update_latest_on_findings
    if update_latest_on_findings?
      Finding.with_repeated.not_repeated.finals(false).find_each do |finding|
        latest_id = finding.id
        cursor    = finding
        findings  = []

        while cursor.repeated_of
          findings << (cursor = cursor.repeated_of)
        end

        findings.each { |f| f.update_column :latest_id, latest_id }
      end
    end
  end

  def update_latest_on_findings?
    Finding.where.not(latest_id: nil).empty?
  end

  def update_review_scopes
    if update_review_scopes?
      PlanItem.where(scope: 'Auditorías/Seguimiento').update_all(scope: 'Auditorías')
      Review.where(scope: 'Auditorías/Seguimiento').update_all(scope: 'Auditorías')
    end
  end

  def update_review_scopes?
    PlanItem.where(scope: 'Auditorías/Seguimiento').any? ||
      Review.where(scope: 'Auditorías/Seguimiento').any?
  end

  def fix_final_latest_findings
    if fix_final_latest_findings?
      final_latest_findings.includes(:latest).find_each do |finding|
        finding.update_column :latest_id, finding.latest.parent_id
      end
    end
  end

  def fix_final_latest_findings?
    final_latest_findings.any?
  end

  def final_latest_findings
    Finding.
      joins(:latest).
      references(:latests_findings).
      where latests_findings: { final: true }
  end

  def fix_email_organization
    if fix_email_organization?
      EMail.where(organization_id: nil).find_each do |e_mail|
        match        = e_mail.subject.match /\A\[(\w+\W*\w*)\]/
        organization = if match && match[1]
                        Organization.where(
                          "LOWER(#{Organization.qcn 'prefix'}) = ?",
                          match[1].downcase
                        ).take
                      end

        e_mail.update_column :organization_id, organization.id if organization
      end
    end
  end

  def fix_email_organization?
    EMail.where(organization_id: nil).any?
  end

  def add_follow_up_audited_privilege
    if follow_up_audited_privilege?
      Privilege.where(module: 'follow_up_reports').find_each do |p|
        attrs = p.attributes.except 'id', 'module', 'created_at', 'updated_at'

        Privilege.create! attrs.merge(module: 'follow_up_reports_audited')
        Privilege.create! attrs.merge(module: 'follow_up_reports_audit')
      end
    end
  end

  def follow_up_audited_privilege?
    Privilege.where(module: 'follow_up_reports_audited').empty? &&
      Privilege.where(module: 'follow_up_reports_audit').empty?
  end

  def add_file_model_review
    if migrate_file_model_review?
      Review.where.not(file_model_id: nil).find_each do |r|
        FileModelReview.create! review_id: r.id, file_model_id: r.file_model_id

        r.update_column :file_model_id, nil
      end
    end
  end

  def migrate_file_model_review?
    FileModelReview.count == 0
  end

  def remove_auditor_junior_role
    if remove_auditor_junior_role?
      Role.where(role_type: 4).update_all role_type: 3
    end
  end

  def remove_auditor_junior_role?
    Role.where(role_type: 4).any?
  end

  def add_commitment_data_on_findings
    if add_commitment_data_on_findings?
      Finding.where.not(reschedule_count: 0).where(commitments: nil).find_each do |finding|
        commitments = finding.calculate_commitments

        finding.update_column :commitments, commitments if commitments.any?
      end
    end
  end

  def add_commitment_data_on_findings?
    Endorsement.any? && Finding.where.not(reschedule_count: 0).where(commitments: nil).all?
  end

  def update_finding_follow_up_date_last_changed
    if update_finding_follow_up_date_last_changed?
      findings = Finding
                 .where(follow_up_date_last_changed: nil)

      findings.each do |finding|
        follow_up_date_last_changed = finding.follow_up_date_last_changed_on_versions

        finding.update_column :follow_up_date_last_changed, follow_up_date_last_changed
      end
    end
  end

  def update_finding_follow_up_date_last_changed?
    Finding
      .where(follow_up_date_last_changed: nil)
      .where.not(follow_up_date: nil).exists?
  end

  def update_draft_review_code
    if update_draft_review_code?
      Organization.all.each do |org|
        if USE_GLOBAL_WEAKNESS_REVIEW_CODE.include? org.prefix

          Weakness.where(organization_id: org.id, parent_id: nil).each do |w|
            w.versions.each do |version|
              break if created_with_final_review_code?(version)

              next if version.object_changes.blank?

              if version_was_in_a_final_review? version
                finding_and_children_update_draft_review_code w, version.object.dig('review_code')

                break
              end
            end
          end

          Oportunity.where(organization_id: org.id, parent_id: nil).each do |o|
            if o.review.has_final_review?
              finding_and_children_update_draft_review_code o, o.review_code

              next
            end

            o.versions.each do |version|
              next if version.object_changes.blank?

              if version_was_in_a_final_review? version
                o.update_column :draft_review_code, version.object.dig('review_code')

                break
              end
            end
          end
        else
          Finding.where(organization_id: org.id).each do |f|
            f.update_column :draft_review_code, f.review_code if f.review.has_final_review?
          end
        end
      end
    end
  end

  def created_with_final_review_code? version
    version.event == 'create' && version.object_changes.dig('review_code')&.second&.size == 8
  end

  def version_was_in_a_final_review? version
    version.object_changes.dig('final')&.second == true ||
      version.object_changes.dig('review_code')&.second&.size == 8
  end

  def finding_and_children_update_draft_review_code finding, new_draft_review_code
    finding.update_column :draft_review_code, new_draft_review_code

    if finding.children.present?
      finding.children.take.update_column :draft_review_code, new_draft_review_code
    end
  end

  def update_draft_review_code?
    Finding.where.not(draft_review_code: nil).blank?
  end

  def update_options_tags
    if update_options_tags?
      Tag.find_each do |tag|
        options = Array(tag.options).each_with_object({}) do |option, hsh|
          hsh[option] = '1'
        end

        tag.update_column :options, options
      end
    end
  end

  def update_options_tags?
    if POSTGRESQL_ADAPTER
      if tag = Tag.where.not(options: nil).take

        tag.options.kind_of? Array
      end
    end
  end

  def update_roles_identifier
    unless roles_identifier_updated?
      Organization.all.each do |org|
        if (org.saml_provider || org.ldap_config) && org.roles.map(&:identifier).all?(&:blank?)
          org.roles.each { |role| role.update_column :identifier, role.name }
        end
      end
    end
  end

  def roles_identifier_updated?
    Role.where.not(identifier: nil).exists?
  end

  def update_status_work_papers
    if update_status_work_papers?
      Review.find_each do |review|
        status = case review.finished_work_papers
        when 'work_papers_not_finished' then 'pending'
        when 'work_papers_finished'     then 'finished'
        when 'work_papers_revised'      then 'revised'
        end

        review.work_papers.each { |wp| wp.update_column :status, status }
      end
    end
  end

  def update_status_work_papers?
    WorkPaper.where(status: nil).exists?
  end

  def update_risk_assessments_changes
    if should_update_risk_assessment_changes?
      update_risk_assessment_weights
      update_risk_assessment_templates
      update_risk_assessments
    end
  end

  def update_risk_assessment_weights
    RiskAssessmentWeight.update_all owner_type: 'RiskAssessmentTemplate'
  end

  def update_risk_assessment_templates
    RiskAssessmentTemplate.find_each do |rat|
      identifier = 'A'

      rat.risk_assessment_weights.each_with_index do |raw, idx|
        raw.update_column :heatmap, true if idx <= 1
        raw.update_column :identifier, identifier

        risk_weights.each do |risk, value|
          raw.risk_score_items.create!(
            name: I18n.t("risk_assessments.risk_weight_risks.#{risk}"),
            value: value
          )
        end

        identifier.next!
      end

      formula = risk_template_make_formula rat

      rat.risk_assessments.update_all formula: formula
      rat.update_column :formula, formula
    end
  end

  def update_risk_assessments
    RiskAssessment.find_each { |ra| ra.send :clone_risk_assessment_weights }
  end

  def should_update_risk_assessment_changes?
    RiskAssessmentTemplate.where(formula: nil).exists?
  end

  def risk_weights
    risk_types = {
      none:        0,
      low:         1,
      medium_low:  2,
      medium:      3,
      medium_high: 4,
      high:        5
    }

    RISK_WEIGHTS.present? ? RISK_WEIGHTS : risk_types
  end

  def risk_template_make_formula rat
    raws = rat.reload.risk_assessment_weights.ordered.pluck :identifier, :weight

    dividend = raws.map { |raw| raw.join(' * ') }.join(' + ')
    divisor  = raws.to_h.values.sum

    "(#{dividend}) / #{divisor}"
  end
