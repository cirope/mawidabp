module ControlObjectiveItems::UpdateCallbacks
  extend ActiveSupport::Concern

  included do
    before_validation :check_if_can_be_modified
  end

  def can_be_modified?
    if is_in_a_final_review? && changed?
      msg = I18n.t 'control_objective_item.readonly'

      errors.add :base, msg if errors.full_messages.exclude? msg

      false
    else
      true
    end
  end

  private

    def check_if_can_be_modified
      throw :abort unless can_be_modified?
    end
end
