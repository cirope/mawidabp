module Tasks::Status
  extend ActiveSupport::Concern

  included do
    enum status: [:pending, :in_progress, :finished]
  end
end
