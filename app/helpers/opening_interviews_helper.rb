module OpeningInterviewsHelper
  def opening_interview_review_field f
    reviews    = Review.list_all_without_opening_interview.order :identification
    collection = reviews.map { |r| [r.identification, r.id] }

    f.input :review_id, collection: collection, prompt: true
  end
end
