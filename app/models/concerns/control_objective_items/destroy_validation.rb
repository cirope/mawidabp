module ControlObjectiveItems::DestroyValidation
  extend ActiveSupport::Concern

  included do
    before_destroy :check_if_can_be_destroyed
  end

  def can_be_destroyed?
    !is_in_a_final_review? && weaknesses.empty? && oportunities.empty?
  end

  private

    def check_if_can_be_destroyed
      throw :abort unless can_be_destroyed?
    end
end
