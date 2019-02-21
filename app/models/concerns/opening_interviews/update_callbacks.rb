module OpeningInterviews::UpdateCallbacks
  extend ActiveSupport::Concern

  included do
    before_validation :check_if_can_be_modified
  end

  def can_be_modified?
    !review&.has_final_review?
  end

  private

    def check_if_can_be_modified
      throw :abort unless can_be_modified?
    end
end
