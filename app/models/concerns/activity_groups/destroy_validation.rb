module ActivityGroups::DestroyValidation
  extend ActiveSupport::Concern

  included do
    before_destroy :check_if_can_be_destroyed
  end

  def can_be_destroyed?
    if activities.all?(&:can_be_destroyed?)
      true
    else
      errors.add :base, :invalid

      false
    end
  end

  private

    def check_if_can_be_destroyed
      throw :abort unless can_be_destroyed?
    end
end