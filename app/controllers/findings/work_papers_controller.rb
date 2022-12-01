class Findings::WorkPapersController < ApplicationController
  include Findings::SetFinding

  respond_to :html

  before_action :auth, :check_privileges
  before_action :set_finding, :set_finding_answer, only: [:create]

  def create
    @work_paper = @finding.work_papers.new work_paper_params

    @work_paper.file.attach @finding_answer.file.blob if @finding_answer.file.attached?

    @work_paper.code_prefix = params[:last_work_paper_code].split.first

    ActiveRecord::Base.no_touching { @work_paper.save }
  end

  private

    def work_paper_params
      {
        name: t(
          '.from_comment',
          user: @finding_answer.user.full_name,
          date: l(@finding_answer.created_at, format: :long)
        ).squish,
        code: next_code
      }
    end

    def next_code
      prefix, number = *params[:last_work_paper_code].split

      [prefix, '%03d' % number.to_i.next].join ' '
    end

    def set_finding_answer
      @finding_answer = @finding.finding_answers.find params[:finding_answer_id]
    end
end
