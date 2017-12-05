module Reports::ReviewsWithIncompleteWorkPapers
  def reviews_with_incomplete_work_papers_report
    status = params[:revised].present? ? :not_revised : :not_finished

    @reviews = Review.list_with_work_papers status: status
  end
end
