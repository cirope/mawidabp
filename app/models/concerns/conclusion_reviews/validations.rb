module ConclusionReviews::Validations
  extend ActiveSupport::Concern

  included do
    validates :review_id, :organization_id, :issue_date, :applied_procedures,
      presence: true
    validates :conclusion, :applied_procedures, :summary, :recipients, :sectors,
      pdf_encoding: true
    validates :type, :summary, length: { maximum: 255 }
    validates :issue_date, timeliness: { type: :date }, allow_nil: true

    validates :recipients, :sectors, presence: true,
      if: :validate_extra_attributes?
  end

  private

    def validate_extra_attributes?
      SHOW_REVIEW_EXTRA_ATTRIBUTES
    end
end
