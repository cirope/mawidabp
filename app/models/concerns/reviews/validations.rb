module Reviews::Validations
  extend ActiveSupport::Concern

  included do
    validates :identification, :period_id, :plan_item_id, :organization_id, presence: true
    validates :description, presence: true, unless: -> { HIDE_REVIEW_DESCRIPTION }
    validates :identification,
      length:      { maximum: 255 },
      format:      { with: /\A\w([.\w\sáéíóúÁÉÍÓÚñÑ-]|\/)*\z/ },
      allow_nil:   true,
      allow_blank: true
    validates :identification, uniqueness: {
      case_sensitive: false, scope: :organization_id
    }, unless: -> { SHOW_REVIEW_AUTOMATIC_IDENTIFICATION }
    validates :identification, :description, :survey, :scope, :risk_exposure,
      :include_sox, pdf_encoding: true
    validates :plan_item_id, uniqueness: { case_sensitive: false }
    validates :score_type, inclusion: {
      in: %w(effectiveness manual none weaknesses)
    }, allow_blank: true, allow_nil: true

    validates :scope,
              :risk_exposure,
              :include_sox,
              presence: true, if: :validate_extra_attributes?

    validates :manual_score, numericality: {
      greater_than_or_equal_to: 0, less_than_or_equal_to: 1000
    }, allow_nil: true, if: :validate_extra_attributes?

    validate :validate_user_roles
    validate :validate_plan_item
    validate :validate_required_business_unit_tag
    validate :validate_required_tags, if: :validate_extra_attributes?
    validate :validate_identification_number_uniqueness,
      on: :create, if: -> { SHOW_REVIEW_AUTOMATIC_IDENTIFICATION }
  end

  private

    def validate_user_roles
      unless has_valid_users?
        errors.add :review_user_assignments, :invalid,
          required_roles: required_roles.to_sentence
      end
    end

    def validate_plan_item
      if plan_item_id && !plan_item&.business_unit
        errors.add :plan_item_id, :invalid
      end
    end

    def has_valid_users?
      has_some_manager = has_supervisor? || has_manager? || has_responsible?

      if DISABLE_REVIEW_AUDITED_VALIDATION
        has_auditor? && has_some_manager
      else
        has_audited? && has_auditor? && has_some_manager
      end
    end

    def validate_extra_attributes?
      SHOW_REVIEW_EXTRA_ATTRIBUTES
    end

    def validate_required_business_unit_tag
      business_unit_type = plan_item&.business_unit&.business_unit_type
      is_invalid = business_unit_type&.require_tag &&
        taggings.reject(&:marked_for_destruction?).blank?

      errors.add :taggings, :blank if is_invalid
    end

    def validate_required_tags
      if will_save_change_to_scope?
        required_tags = REVIEW_SCOPES[scope]&.fetch(:require_tags, nil) || []
        needed_tags   = required_tags.flat_map { |option| Tag.list.with_option option }.uniq

        if needed_tags.any? && (needed_tags & tags).empty?
          errors.add :taggings, :missing_tags_for_scope,
            r_scope: scope,
            tags:    needed_tags.map(&:to_s).to_sentence
        end
      end
    end

    def validate_identification_number_uniqueness
      suffix = identification.to_s.split('-').last
      conditions = [
        "#{Review.quoted_table_name}.#{Review.qcn 'organization_id'} = :organization_id",
        "#{Review.quoted_table_name}.#{Review.qcn 'identification'} LIKE :identification"
      ].join(' AND ')

      if suffix.present?
        is_taken = Review.unscoped.where(
          conditions,
          organization_id: organization_id,
          identification: "%#{suffix}"
        ).any?

        errors.add :identification, :taken if is_taken
      end
    end

    def required_roles
      required_roles = [
        [
          I18n.t('review.user_assignment.type_manager'),
          I18n.t('label.or'),
          I18n.t('review.user_assignment.type_supervisor')
        ].join(' '),
        I18n.t('review.user_assignment.type_auditor')
      ]

      unless DISABLE_REVIEW_AUDITED_VALIDATION
        required_roles << I18n.t('review.user_assignment.type_audited')
      end

      required_roles
    end
end
