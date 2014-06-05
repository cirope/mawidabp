module ErrorRecords::Defaults
  extend ActiveSupport::Concern
  include ErrorRecords::Constants

  included do
    before_validation :set_defaults
  end

  private

    def set_defaults
      self.error ||= ERRORS[error_type] if error_type
      self.data  ||= "IP: [#{request.ip}], B: [#{request.user_agent}]" if request
      self.data  = "U: [#{user_name}], " + data if user.blank? && user_name
    end
end
