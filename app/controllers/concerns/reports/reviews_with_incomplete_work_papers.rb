module Reports::ReviewsWithIncompleteWorkPapers
  def reviews_with_incomplete_work_papers_report
    @reviews = Review.list_with_incomplete_work_papers.none
  end
end
