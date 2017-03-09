module Organizations::DestroyValidation
  extend ActiveSupport::Concern

  included do
    before_destroy :check_if_can_be_destroyed
  end

  private

    def can_be_destroyed?
      if best_practices.all?(&:can_be_destroyed?)
        true
      else
        _errors = best_practices.map do |bp|
          bp.errors.full_messages.join APP_ENUM_SEPARATOR
        end

        errors.add :base, _errors.reject(&:blank?).join(APP_ENUM_SEPARATOR)

        false
      end
    end

  private

    def check_if_can_be_destroyed
      throw :abort unless can_be_destroyed?
    end
end
