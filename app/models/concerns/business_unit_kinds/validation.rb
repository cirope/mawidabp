module BusinessUnitKinds::Validation
  extend ActiveSupport::Concern

  included do
    before_destroy :check_if_can_be_destroyed

    validates :name, presence: true,
      length: { maximum: 255 },
      uniqueness: { case_sensitive: false }
  end

  private

    def check_if_can_be_destroyed
      throw :abort unless can_be_destroyed?
    end

    def can_be_destroyed?
      has_any_related = business_units.any?

      if has_any_related
        errors.add :base,
          I18n.t('business_unit_kind.errors.business_unit_kind_related')

        false
      else
        true
      end
    end
end
