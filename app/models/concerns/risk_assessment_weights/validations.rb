module RiskAssessmentWeights::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :description, :identifier, presence: true, pdf_encoding: true
    validates :name, :identifier, length: { maximum: 255 }, allow_blank: true

    validate :uniqueness_name
    validate :uniqueness_identifier
    validate :risk_score_items_presence
  end

  private

    def uniqueness_identifier
      validate_uniqueness_for :identifier
    end

    def uniqueness_name
      validate_uniqueness_for :name
    end

    def risk_score_items_presence
      unless risk_score_items.reject(&:marked_for_destruction?).any?
        errors.add :risk_score_items, :blank
      end
    end

    def validate_uniqueness_for attr
      if send(attr).present?
        raws = risk_assessment_template.risk_assessment_weights.reject do |raw|
          raw == self || raw.marked_for_destruction?
        end

        if raws.select { |raw| raw.send(attr).strip =~ /#{Regexp.quote(send(attr).strip)}/i }.any?
          errors.add attr, :taken
        end
      end
    end
end
