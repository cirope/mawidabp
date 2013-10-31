module Organizations::Setting 
  extend ActiveSupport::Concern

  included do
    after_create :create_settings

    has_many :settings, dependent: :destroy
  end

  def create_settings
    DEFAULT_SETTINGS.each do |k,v|
      settings.create(
        name: k, value: v, description: I18n.t("setting.#{k}")
      )
    end 
  end
end
