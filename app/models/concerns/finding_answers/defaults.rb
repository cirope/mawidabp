module FindingAnswers::Defaults
  extend ActiveSupport::Concern

  included do
    after_initialize :set_defaults, if: :new_record?
  end

  private

    def set_defaults
      self.notify_users = true if notify_users.nil?
    end
end
