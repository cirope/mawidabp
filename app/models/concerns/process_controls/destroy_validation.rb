module ProcessControls::DestroyValidation
  extend ActiveSupport::Concern

  included do
    before_destroy :can_be_destroyed?
  end

  def can_be_destroyed?
    if control_objectives.all?(&:can_be_destroyed?)
      true
    else
      errors.add :base, :invalid

      false
    end
  end
end
