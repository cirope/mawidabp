class Findings::FollowUpPdfController < ApplicationController
  def show
    finding = scoped_findings.find params[:id]
    path    = finding.absolute_follow_up_pdf_path

    finding.follow_up_pdf current_organization

    FileRemoveJob.set(wait: 15.minutes).perform_later path

    redirect_to finding.relative_follow_up_pdf_path
  end

  private

    def scoped_findings
      current_organization.corporate? ? Finding.group_list : Finding.list
    end
end
