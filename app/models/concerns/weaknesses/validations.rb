module Weaknesses::Validations
  extend ActiveSupport::Concern

  included do
    before_validation :clean_array_attributes

    validates :risk, :priority, presence: true
    validates :audit_recommendations, presence: true, if: :notify?
    validate :review_code_has_valid_prefix
    validates :impact_risk, :probability, presence: true, if: :require_impact_risk_and_probability?

    validates :compliance, length: { maximum: 255 },
      allow_nil: true, allow_blank: true
    validates :tag_ids,
      presence: true,
      length: { minimum: 2 }, if: :validate_tags_presence?
    validates :compliance,
              :operational_risk,
              :impact,
              :internal_control_components,
              presence: true, if: :validate_extra_attributes?
    validates :compliance_observations, presence: true, if: :compliance_require_observations?
    validates :state_regulations,
              :degree_compliance,
              :observation_originated_tests,
              :sample_deviation, :impact_risk,
              :probability, :external_repeated,
              presence: true, if: :bic_require_is_manual_risk_disabled?
    validates :risk_justification, presence: true, if: :bic_require_is_manual_risk_enabled?
  end

  private

    def bic_require_is_manual_risk_disabled?
      Current.conclusion_pdf_format == 'bic' && !manual_risk
    end

    def bic_require_is_manual_risk_enabled?
      Current.conclusion_pdf_format == 'bic' && manual_risk
    end

    def require_impact_risk_and_probability?
      USE_SCOPE_CYCLE && !manual_risk
    end

    def compliance_require_observations?
      SHOW_WEAKNESS_EXTRA_ATTRIBUTES && compliance == 'yes'
    end

    def review_code_has_valid_prefix
      regex = if Current.global_weakness_code && (parent || children.any?)
               /\A#{prefix}\d+\Z/
             else
               revoked_prefix = I18n.t 'code_prefixes.revoked'

               /\A#{revoked_prefix}?#{prefix}\d+\Z/
             end

      errors.add :review_code, :invalid unless review_code =~ regex
    end

    def validate_tags_presence?
      WEAKNESS_TAG_VALIDATION_START && (
        new_record? ||
        review&.conclusion_final_review&.blank? ||
        created_at >= WEAKNESS_TAG_VALIDATION_START
      )
    end

    def validate_extra_attributes?
      SHOW_WEAKNESS_EXTRA_ATTRIBUTES
    end

    def clean_array_attributes
      self.impact = Array(impact).reject &:blank?
      self.operational_risk = Array(operational_risk).reject &:blank?
      self.internal_control_components =
        Array(internal_control_components).reject &:blank?
    end
end
