module ProcessControls::DestroyValidation
  extend ActiveSupport::Concern

  included do
    before_destroy :can_be_destroyed?
  end

  def can_be_destroyed?
    unless control_objectives.all?(&:can_be_destroyed?)
      errors.add :base, :invalid

      false
    end
  end
end
