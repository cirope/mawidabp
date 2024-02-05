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
end
