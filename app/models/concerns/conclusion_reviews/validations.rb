module ConclusionReviews::Validations
  extend ActiveSupport::Concern

  included do
    validates :review_id, :organization_id, :issue_date, presence: true
    validates :applied_procedures, presence: true, unless: :validate_extra_gal_attributes?
    validates :conclusion, :applied_procedures, :summary, :recipients, :sectors,
      :observations, :objective, :reference, :scope, pdf_encoding: true
    validates :type, :summary, :evolution, :previous_identification,
      length: { maximum: 255 }
    validates :issue_date, :previous_date, timeliness: { type: :date },
      allow_blank: true

    validates :sectors, :evolution, :evolution_justification, presence: true,
      if: :validate_extra_gal_attributes?
    validates :recipients, presence: true, if: :validate_recipients?
    validates :main_weaknesses_text, presence: true,
      if: :validate_short_alternative_pdf_attributes?
    validates :objective, presence: true, if: :validate_extra_bic_attributes?
    validates :previous_identification, presence: true, if: :previous_date_present?
    validates :previous_date, presence: true, if: :previous_identification_present?
    validate :evolution_for_conclusion, if: :validate_extra_gal_attributes?
  end

  private

    def evolution_for_conclusion
      allowed = Array(CONCLUSION_EVOLUTION[conclusion])

      errors.add :evolution, :invalid if allowed.exclude?(evolution)
    end

    def validate_extra_gal_attributes?
      Current.conclusion_pdf_format == 'gal'
    end

    def validate_extra_bic_attributes?
      Current.conclusion_pdf_format == 'bic'
    end

    def previous_date_present?
      previous_date.present?
    end

    def previous_identification_present?
      previous_identification.present?
    end

    def validate_recipients?
      %w(bic gal).include? Current.conclusion_pdf_format
    end

    def validate_short_alternative_pdf_attributes?
      ORGANIZATIONS_WITH_BEST_PRACTICE_COMMENTS.include? Current.organization.prefix
    end
end
