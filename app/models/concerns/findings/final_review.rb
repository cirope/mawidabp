module Findings::FinalReview
  extend ActiveSupport::Concern

  def check_for_final_review(_)
    if !marked_for_destruction? && final? && review&.is_frozen?
      raise 'Conclusion Final Review frozen'
    end
  end

  def issue_date
    review&.conclusion_final_review&.issue_date
  end
end
