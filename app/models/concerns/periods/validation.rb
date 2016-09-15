module Periods::Validation
  extend ActiveSupport::Concern

  included do
    validates :number, numericality: { only_integer: true },
      allow_nil: true
    validates :number, :start, :end, :description, :organization,
      presence: true
    validates :number, uniqueness: { scope: :organization }
    validates :description, pdf_encoding: true
    validates_date :start, allow_nil: true, allow_blank: true
    validates_date :end, allow_nil: true, allow_blank: true, after: :start
  end
end
