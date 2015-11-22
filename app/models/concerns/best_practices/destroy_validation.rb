module BestPractices::DestroyValidation
  extend ActiveSupport::Concern

  included do
    before_destroy :can_be_destroyed?
  end

  # Warning: must be public method
  def can_be_destroyed?
    unless process_controls.all?(&:can_be_destroyed?)
      errors.add :base, :invalid

      false
    end
  end
end
