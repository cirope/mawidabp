module BestPracticeComments::UpdateCallbacks
  extend ActiveSupport::Concern

  included do
    before_validation :check_if_can_be_modified
  end

  private

    def check_if_can_be_modified
      throw :abort if review&.has_final_review?
    end
end
