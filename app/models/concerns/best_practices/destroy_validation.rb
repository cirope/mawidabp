module BestPractices::DestroyValidation
  extend ActiveSupport::Concern

  included do
    before_destroy :can_be_destroyed?
  end

  # Warning: must be public method
  def can_be_destroyed?
    unless process_controls.all?(&:can_be_destroyed?)
      _errors = process_controls.map do |pc|
        pc.errors.full_messages.join APP_ENUM_SEPARATOR
      end

      errors.add :base, _errors.reject(&:blank?).join(APP_ENUM_SEPARATOR)

      false
    end
  end
end
