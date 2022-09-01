module WorkPapers::Review
  extend ActiveSupport::Concern

  included do
    after_save :mark_review_as_not_finished, unless: :skip_mark_as_not_finished?
  end

  private

    def skip_mark_as_not_finished?
      review = owner.review

      Current.user.supervisor? && review.work_papers_finished?
    end

    def mark_review_as_not_finished
      review = owner.review

      def review.can_be_modified?; true; end

      review.work_papers_not_finished!
      review.save! validate: false
    end
end
