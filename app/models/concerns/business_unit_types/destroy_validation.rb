module BusinessUnitTypes::DestroyValidation
  extend ActiveSupport::Concern

  included do
    before_destroy :check_if_can_be_destroyed
  end

  def can_be_destroyed?
    business_units.all? &:can_be_destroyed?
  end

  private

    def check_if_can_be_destroyed
      throw :abort unless can_be_destroyed?
    end
end
