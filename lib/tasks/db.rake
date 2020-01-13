namespace :db do
  desc 'Put records, remove and update the database using current app values'
  task update: :environment do
    ActiveRecord::Base.transaction do
      update_organization_settings        # 2017-03-15
      add_new_answer_options              # 2017-06-29
      add_best_practice_privilege         # 2018-01-31
      add_control_objective_privilege     # 2018-01-31
      add_task_codes                      # 2018-07-24
      mark_tasks_as_finished              # 2019-01-04
      update_finding_first_follow_up_date # 2019-01-07
      reset_notification_level            # 2019-03-06
      update_finding_reschedule_count     # 2019-07-19
      complete_main_recommendations       # 2019-07-23
      update_tag_style                    # 2019-09-26
      update_tag_icons                    # 2019-09-30
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

  def add_new_answer_options
    if add_new_answer_options?
      Question.where(answer_type: Question::ANSWER_TYPES[:multi_choice]).each do |q|
        q.answer_options.create! option: 'not_apply'
      end
    end
  end

  def add_new_answer_options?
    AnswerOption.where(
      "#{AnswerOption.quoted_table_name}.#{AnswerOption.qcn 'option'} LIKE ?",
      'not_apply'
    ).empty?
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
    pending_statuses = [
      Finding::STATUS[:being_implemented],
      Finding::STATUS[:awaiting]
    ]

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
