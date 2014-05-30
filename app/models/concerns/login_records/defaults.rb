module LoginRecords::Defaults
  extend ActiveSupport::Concern

  included do
    after_initialize :set_defaults
  end

  private

    def set_defaults
      self.start ||= Time.now
      self.data ||= "IP: [#{request.ip}], B: [#{request.user_agent}]" if request
    end
end
