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
  end

  private

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
