namespace :db do
  desc 'Put records, remove and update the database using current app values'
  task update: :environment do
    ActiveRecord::Base.transaction do
      update_organization_settings        # 2017-03-15
      add_new_answer_options              # 2017-06-29
      add_best_practice_privilege         # 2018-01-31
      add_control_objective_privilege     # 2018-01-31
      add_task_codes                      # 2018-07-24
      update_finding_reschedules          # 2018-11-27
      mark_tasks_as_finished              # 2019-01-04
      update_finding_first_follow_up_date # 2019-01-07
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

  def update_finding_reschedules
    if update_finding_reschedules?
      Finding.where(rescheduled: false).find_each do |finding|
        update = finding.final == false ||
          finding.repeated_of&.mark_as_rescheduled?

        if update && finding.mark_as_rescheduled?
          finding.update_column :rescheduled, true
        end
      end
    end
  end

  def update_finding_reschedules?
    Finding.where(rescheduled: true).empty?
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
      where.not(follow_up_date: nil).count > 0
  end
