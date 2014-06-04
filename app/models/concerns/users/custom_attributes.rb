module Users::CustomAttributes
  extend ActiveSupport::Concern

  included do
    attr_accessor :user_data, :send_notification_email, :nested_user, :reallocation_errors

    alias_attribute :informal, :user
  end
end
