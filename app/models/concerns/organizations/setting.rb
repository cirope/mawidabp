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
    setting(:skip_function_and_manager_from_ldap_sync) != '0'
  end

  def skip_reiteration_copy?
    setting(:skip_reiteration_copy) != '0'
  end

  def finding_state_change_notification?
    setting(:finding_state_change_notification) != '0'
  end

  private

    def setting name
      setting = settings.find_by name: name

      setting ? setting.value : DEFAULT_SETTINGS[name][:value]
    end
end
