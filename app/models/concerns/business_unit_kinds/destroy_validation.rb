module BusinessUnitKinds::DestroyValidation
  extend ActiveSupport::Concern

  included do
    before_destroy :check_if_can_be_destroyed
  end

  def can_be_destroyed?
    if business_units.any?
      errors.add :base,
        I18n.t('business_unit_kind.errors.business_unit_kind_related')

      false
    else
      true
    end
  end

  private

    def check_if_can_be_destroyed
      throw :abort unless can_be_destroyed?
    end
end
