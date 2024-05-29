module Organizations::Setting
  extend ActiveSupport::Concern

  included do
    after_create :create_settings

    has_many :settings, dependent: :destroy
  end

  def create_settings
    DEFAULT_SETTINGS.each do |k,v|
      settings.create!(
        name: k, value: v[:value], description: I18n.t("settings.#{k}")
      )
    end
  end

  def finding_by_current_user?
    setting = settings.find_by name: 'finding_by_current_user'
    result  = (setting ? setting.value : DEFAULT_SETTINGS[:finding_by_current_user][:value]) != '0'

    result
  end

  def skip_function_and_manager?
    setting = settings.find_by(
      name: 'skip_function_and_manager_from_ldap_sync'
    )

    value = if setting
              setting.value
            else
              DEFAULT_SETTINGS[:skip_function_and_manager_from_ldap_sync][:value]
            end

    value != '0'
  end
end
