module ConclusionReviews::Validations
  extend ActiveSupport::Concern

  included do
    validates :review_id, :organization_id, :issue_date, :applied_procedures,
      presence: true
    validates :conclusion, :applied_procedures, :summary, pdf_encoding: true
    validates :type, :summary, length: { maximum: 255 }
    validates :issue_date, timeliness: { type: :date }, allow_nil: true
  end
end
