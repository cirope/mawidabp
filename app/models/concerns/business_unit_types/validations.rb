module BusinessUnitTypes::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :business_unit_label, presence: true
    validates :review_prefix, presence: true, uniqueness: {
      case_sensitive: false, scope: :organization_id
    }, if: :review_prefix_should_be_checked?
    validates :name, :business_unit_label, :project_label, :review_prefix,
      length: { maximum: 255 }, allow_nil: true, allow_blank: true
    validates :name, uniqueness: {
      case_sensitive: false, scope: :organization_id
    }
    validate :all_units_marked_for_destruction_can_be_destroyed
    validate :exec_summary_intro_must_have_valid_keys, if: :is_gal?
  end

  private

    def is_gal?
      Current.conclusion_pdf_format == 'gal'
    end

    def exec_summary_intro_must_have_valid_keys
      field_keys   = exec_summary_intro.scan(/%\{(.*?)\}/).flatten
      valid_keys   = ['informe']
      missing_keys = field_keys - valid_keys

      if missing_keys.any?
        errors.add :exec_summary_intro, :missing_keys, count: missing_keys.count,
          valid_keys: valid_keys.to_sentence, invalid_keys: missing_keys.to_sentence
      end
    end

    def all_units_marked_for_destruction_can_be_destroyed
      locked = business_units.any? do |bu|
        bu.marked_for_destruction? && !bu.can_be_destroyed?
      end

      errors.add :business_units, :locked if locked
    end

    def review_prefix_should_be_checked?
      SHOW_REVIEW_AUTOMATIC_IDENTIFICATION
    end
end
