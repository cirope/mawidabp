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
      length: { minimum: :min_tag_count }, if: :validate_tags_presence?
    validates :compliance,
              :operational_risk,
              :impact,
              :internal_control_components,
              presence: true, if: :validate_extra_attributes?
    validates :compliance_observations, presence: true, if: :compliance_require_observations?
    validate :fields_bic_cannot_modified
  end

  private

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

    def min_tag_count
      prefix = organization&.prefix

      WEAKNESS_TAG_COUNT_BY_ORGANIZATION.include?(prefix) ? WEAKNESS_TAG_COUNT_BY_ORGANIZATION[prefix].to_i : 2
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

    def fields_bic_cannot_modified
      if repeated_of.present?
        %i[year nsisio nobs].each do |attr|
          errors.add attr, :different_from_repeated_of if self[attr] != repeated_of[attr]
        end
      elsif fields_bic_frozen?
        %i[year nsisio nobs].each { |attr| errors.add attr, :frozen if send("#{attr}_changed?") }
      end
    end

    def fields_bic_frozen?
      review.try(:is_frozen?) || repeated?
    end
end
