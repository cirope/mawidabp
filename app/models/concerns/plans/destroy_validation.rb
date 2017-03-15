module Plans::DestroyValidation
  extend ActiveSupport::Concern

  included do
    before_destroy :check_if_can_be_destroyed
  end

  def can_be_destroyed?
    if plan_items.all?(&:can_be_destroyed?)
      true
    else
      _errors = plan_items.map do |pi|
        pi.errors.full_messages.join APP_ENUM_SEPARATOR
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
