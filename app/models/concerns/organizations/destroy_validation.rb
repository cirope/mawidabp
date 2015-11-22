module Organizations::DestroyValidation
  extend ActiveSupport::Concern

  included do
    before_destroy :can_be_destroyed?
  end

  private

    def can_be_destroyed?
      unless best_practices.all?(&:can_be_destroyed?)
        _errors = best_practices.map do |bp|
          bp.errors.full_messages.join APP_ENUM_SEPARATOR
        end

        errors.add :base, _errors.reject(&:blank?).join(APP_ENUM_SEPARATOR)

        false
      end
    end
end
