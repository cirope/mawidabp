module Risks::Validation
  extend ActiveSupport::Concern

  included do
    LIKELIHOODS = {
      insignificant: 1,
      minor:         2,
      moderate:      3,
      high:          4,
      catastrophic:  5
    }

    IMPACTS = {
      rare:           1,
      unlikely:       2,
      moderate:       3,
      likely:         4,
      almost_certain: 5
    }

    validates :name, :identifier, :likelihood, :impact,
      presence: true
    validates :name, :identifier,
      pdf_encoding: true,
      length: { maximum: 255 },
      uniqueness: { case_sensitive: false, scope: :risk_category_id },
      allow_nil: true, allow_blank: true
    validates :likelihood,
      inclusion: { in: LIKELIHOODS.values },
      allow_nil: true, allow_blank: true
    validates :impact,
      inclusion: { in: IMPACTS.values },
      allow_nil: true, allow_blank: true

    validate :uniqueness_name
    validate :uniqueness_identifier
  end

  private

    def uniqueness_identifier
      validate_uniqueness_for :identifier
    end

    def uniqueness_name
      validate_uniqueness_for :name
    end

    def validate_uniqueness_for attr
      if send(attr).present?
        risks = risk_category.risks.reject do |rk|
          rk == self || rk.marked_for_destruction?
        end

        if risks.select { |rk| rk.send(attr).strip =~ /^#{Regexp.quote(send(attr).strip)}$/i }.any?
          errors.add attr, :taken
        end
      end
    end
end