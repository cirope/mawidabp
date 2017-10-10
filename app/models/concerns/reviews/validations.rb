module Reviews::Validations
  extend ActiveSupport::Concern

  included do
    validates :identification, :period_id, :plan_item_id, :organization_id, presence: true
    validates :description, presence: true, unless: -> { HIDE_REVIEW_DESCRIPTION }
    validates :identification,
      length:     { maximum: 255 },
      format:     { with: /\A\w[\w\s-]*\z/ }, allow_nil: true, allow_blank: true,
      uniqueness: { case_sensitive: false, scope: :organization_id }
    validates :identification, :description, :survey, pdf_encoding: true
    validates :plan_item_id, uniqueness: { case_sensitive: false }

    validate :validate_user_roles
    validate :validate_plan_item
  end

  private

    def validate_user_roles
      errors.add :review_user_assignments, :invalid unless has_valid_users?
    end

    def validate_plan_item
      if plan_item_id && !plan_item&.business_unit
        errors.add :plan_item_id, :invalid
      end
    end

    def has_valid_users?
      has_audited? && has_auditor? && (has_supervisor? || has_manager?)
    end
end
