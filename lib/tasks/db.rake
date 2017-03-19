namespace :db do
  desc 'Put records, remove and update the database using current app values'
  task update: :environment do
    update_organization_settings
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
