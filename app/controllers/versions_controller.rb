class VersionsController < ApplicationController
  respond_to :html, :pdf

  before_action :auth, :check_privileges
  before_action :set_title

  def index
    @versions = search

    respond_to do |format|
      format.html { @versions = @versions.page(params[:page]) }
      format.pdf  { redirect_to pdf.relative_path }
    end
  end

  # * GET /versions/1
  def show
    @version = PaperTrail::Version.where(
      id: params[:id], organization_id: current_organization.id, important: true
    ).first
  end

  private

    def pdf
      VersionPdf.create from: @from_date, to: @to_date, versions: @versions, current_organization: current_organization
    end

    def search
      @from_date, @to_date = *make_date_range(params[:index])

      PaperTrail::Version.where(conditions, parameters).order('created_at DESC')
    end

    def conditions
      [
        'organization_id = :organization_id',
        'created_at BETWEEN :from_date AND :to_date',
        'item_type IN (:types)', 'important = :boolean_true'
      ].join(' AND ')
    end

    def parameters
      {
        from_date: @from_date.to_time.at_beginning_of_day,
        to_date: @to_date.to_time.at_end_of_day,
        organization_id: current_organization.id,
        types: ['User', 'Parameter'], boolean_true: true
      }
    end
end
