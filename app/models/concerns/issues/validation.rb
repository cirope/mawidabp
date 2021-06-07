module Issues::Validation
  extend ActiveSupport::Concern

  included do
    validates :customer, :entry, :operation, length: { maximum: 255 },
      allow_nil: true, allow_blank: true
    validates :close_date, timeliness: { type: :date }, allow_blank: true
    validates :customer, :entry, :operation, :comments, pdf_encoding: true
    validates :amount, numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 9_999_999_999_999.99
    }, allow_nil: true, allow_blank: true
  end
end
