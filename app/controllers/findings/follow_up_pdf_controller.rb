class Findings::FollowUpPdfController < ApplicationController
  include Findings::SetFinding

  def show
    finding = scoped_findings.find params[:id]
    path    = finding.absolute_follow_up_pdf_path

    finding.follow_up_pdf current_organization, brief: params[:brief].present?

    FileRemoveJob.set(wait: 15.minutes).perform_later path

    redirect_to finding.relative_follow_up_pdf_path
  end
end
