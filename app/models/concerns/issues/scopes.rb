module Issues::Scopes
  extend ActiveSupport::Concern

  included do
    scope :without_close_date, -> { where close_date: nil }
  end
end
