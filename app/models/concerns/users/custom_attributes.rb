module Users::CustomAttributes
  extend ActiveSupport::Concern

  included do
    attr_accessor :user_data, :send_notification_email, :reallocation_errors

    alias_attribute :informal, :user
  end
end
