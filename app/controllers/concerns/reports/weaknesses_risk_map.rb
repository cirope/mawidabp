module Reports::WeaknessesRiskMap
  extend ActiveSupport::Concern

  include Reports::FileResponder

  included do
    before_action :set_weaknesses_for_risk_map,
      :set_title,
      only: [:weaknesses_risk_map, :create_weaknesses_risk_map]
  end

  def weaknesses_risk_map
    respond_to do |format|
      format.html
      format.csv  { render_weaknesses_report_csv }
    end
  end

  def create_weaknesses_risk_map
    redirect_or_send_by_mail(
      collection:    @weaknesses,
      method_name:   :by_risk_map,
      filename:      weaknesses_report_pdf_name,
      options:       {
        title:         params[:report_title],
        subtitle:      params[:report_subtitle],
        days:          params[:days],
        before_committee_date: params[:before_committee_date],
        current_committee_date: params[:current_committee_date],
        report_params: Hash(params[:weaknesses_report]&.permit!),
        filename:      weaknesses_report_pdf_name
      }
    )
  end

  private

    def set_weaknesses_for_risk_map
      report_params = params[:weaknesses_risk_map]

      if report_params.present?
        weaknesses = filter_weaknesses_for_report report_params
        order      = weaknesses.values[:order]

        @weaknesses = scoped_weaknesses.where(
          id: weaknesses.pluck(:id)
        ).includes(
          :finding_user_assignments,
          :repeated_of,
          :repeated_in,
          latest: :review,
          review: :plan_item,
          finding_answers: [:file_model, user: { organization_roles: :role }],
          users: { organization_roles: :role },
          control_objective_item: [:process_control]
        ).merge(
          Review.allowed_by_business_units
        ).order order
      else
        @weaknesses = Weakness.none
      end
    end

    def set_title
      @title = t 'follow_up_committee_report.weaknesses_risk_map_title'
    end

    def scoped_weaknesses
      Weakness.limit(10)
    end

    def filter_weaknesses_for_report report_params
      weaknesses = scoped_weaknesses.finals false
    end

    def render_weaknesses_report_csv
      render_or_send_by_mail(
        collection:  @weaknesses,
        filename:    "#{@title.downcase}.csv",
        method_name: :by_risk_map
      )
    end
end
