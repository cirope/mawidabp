module Reports::WeaknessesRiskMap
  extend ActiveSupport::Concern

  include Reports::FileResponder

  included do
    before_action :set_weaknesses_for_risk_map,
      :set_title, only: :weaknesses_risk_map
  end

  def weaknesses_risk_map
    respond_to do |format|
      format.html
      format.csv { render_weaknesses_report_csv }
    end
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
          review: :plan_item,
          control_objective_item: [:process_control]
        ).order order
      else
        @weaknesses = Weakness.none
      end
    end

    def set_title
      @title = t 'follow_up_committee_report.weaknesses_risk_map_title'
    end

    def scoped_weaknesses
      Weakness.where('created_at >= ?', 4.years.ago).
        where.not(state: Finding::STATUS[:repeated])
    end

    def filter_weaknesses_for_report report_params
      weaknesses = scoped_weaknesses.finals false

      if report_params[:organization_ids].present?
        organization_ids = Array(report_params[:organization_ids]).reject(&:blank?).map &:to_i
        weaknesses       = weaknesses.where organization_id: organization_ids if organization_ids.present?
      end

      weaknesses
    end

    def render_weaknesses_report_csv
      render_or_send_by_mail(
        collection:  @weaknesses,
        filename:    "#{@title.downcase}.csv",
        method_name: :by_risk_map,
        options:     Hash(params[:weaknesses_risk_map]&.permit!)
      )
    end
end
