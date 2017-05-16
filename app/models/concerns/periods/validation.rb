module Periods::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, :start, :end, :description, :organization, presence: true
    validates :name, uniqueness: { scope: :organization }
    validates :description, pdf_encoding: true
    validates_date :start, allow_nil: true, allow_blank: true
    validates_date :end, allow_nil: true, allow_blank: true, after: :start
  end
end
