module WorkPapers::Review
  extend ActiveSupport::Concern

  included do
    after_save :mark_review_as_not_finished
  end

  private

    def mark_review_as_not_finished
      review = owner.review

      def review.can_be_modified?; true; end

      review.work_papers_not_finished!
      review.save! validate: false
    end
end
