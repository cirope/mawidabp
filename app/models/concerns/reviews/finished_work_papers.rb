module Reviews::FinishedWorkPapers
  extend ActiveSupport::Concern

  included do
    attr_accessor :updated_from_work_paper

    enum finished_work_papers: [
      :work_papers_not_finished,
      :work_papers_finished,
      :work_papers_revised
    ]

    after_update_commit :update_work_paper_status, if: :should_be_update_work_papers_status?
  end

  def update_status status
    work_papers_status = work_papers.map(&:reload).map(&:status).uniq

    if work_papers_status.include?    'pending'
      work_papers_not_finished! unless work_papers_not_finished?
    elsif work_papers_status.include? 'finished'
      work_papers_finished!     unless work_papers_finished?
    elsif work_papers_status.include? 'revised'
      work_papers_revised!      unless work_papers_revised?
    end
  end

  private

    def should_be_update_work_papers_status?
      !updated_from_work_paper && saved_change_to_finished_work_papers?
    end

    def update_work_paper_status
      status = case finished_work_papers
      when 'work_papers_not_finished' then 'pending'
      when 'work_papers_finished'     then 'finished'
      when 'work_papers_revised'      then 'revised'
      end

      work_papers.each { |wp| wp.update_column :status, status }
    end
end
