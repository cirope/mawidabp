module Notifications::Validation
  extend ActiveSupport::Concern

  included do
    validates :confirmation_hash, :user, presence: true
    validates :status, inclusion: { in: Notification::STATUS.values }
    validates :confirmation_hash, length: { maximum: 255 }, allow_nil: true,
      allow_blank: true
    validates :notes, pdf_encoding: true
    validates_datetime :confirmation_date, allow_nil: true, allow_blank: true
  end
end
