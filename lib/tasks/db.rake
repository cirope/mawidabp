namespace :db do
  desc 'Put records, remove and update the database using current app values'
  task update: :environment do
    update_organization_settings
    add_new_answer_options
  end
end

private

  def update_organization_settings
    if add_show_print_date_on_pdfs?
      Organization.all.each do |o|
        o.settings.create! name:        'show_print_date_on_pdfs',
                           value:       DEFAULT_SETTINGS[:show_print_date_on_pdfs][:value],
                           description: I18n.t('settings.show_print_date_on_pdfs')
      end
    end
  end

  def add_show_print_date_on_pdfs?
    Setting.where(name: 'show_print_date_on_pdfs').empty?
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
