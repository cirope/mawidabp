module Reviews::FinishedWorkPapers
  extend ActiveSupport::Concern

  included do
    enum finished_work_papers: [
      :work_papers_not_finished,
      :work_papers_finished,
      :work_papers_revised
    ]
  end
end
