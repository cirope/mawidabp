module ErrorRecords::Defaults
  extend ActiveSupport::Concern

  included do
    ERRORS = { on_login: 1, on_password_change: 2, user_disabled: 3 }.freeze

    before_validation :set_defaults
  end

  private

    def set_defaults
      self.error ||= ERRORS[error_type] if error_type
      self.data  ||= "IP: [#{request.ip}], B: [#{request.user_agent}]" if request
      self.data  = "U: [#{user_name}], " + data if user.blank? && user_name
    end
end
