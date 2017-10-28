module Findings::FinalReview
  extend ActiveSupport::Concern

  def check_for_final_review(_)
    raise 'Conclusion Final Review frozen' if final? && review&.is_frozen?
  end

  def issue_date
    review&.conclusion_final_review&.issue_date
  end
end
