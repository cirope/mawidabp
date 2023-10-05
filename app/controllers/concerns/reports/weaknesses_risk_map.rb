module Reports::WeaknessesRiskMap
  extend ActiveSupport::Concern

  include Reports::FileResponder

  included do
    before_action :set_weaknesses_for_risk_map,
      :set_title_risk_map, only: :weaknesses_risk_map
  end

  def weaknesses_risk_map
    respond_to do |format|
      format.html
      format.csv { render_weaknesses_risk_map_csv }
    end
  end

  private

    def set_weaknesses_for_risk_map
      report_params = params[:weaknesses_risk_map]

      if report_params.present?
        weaknesses = filter_weaknesses_for_report report_params

        conditions = []
        parameters = {}

        weaknesses.pluck(:id).each_slice(1000).with_index do |finding_ids, i|
          conditions << "#{Finding.quoted_table_name}.#{Finding.qcn 'id'} IN (:ids_#{i})"
          parameters[:"ids_#{i}"] = finding_ids
        end

        @weaknesses = weaknesses.where(
          conditions.map { |c| "(#{c})" }.join(' OR '), parameters).
            includes(
              review: :plan_item,
              control_objective_item: [:process_control]
            )
      else
        @weaknesses = Weakness.none
      end
    end

    def set_title_risk_map
      @title = t 'follow_up_committee_report.weaknesses_risk_map_title'
    end

    def scoped_risk_map_finding
      Weakness.where(created_at: 4.years.ago..).
        where.not(state: Finding::STATUS[:repeated])
    end

    def filter_weaknesses_for_report report_params
      weaknesses = scoped_risk_map_finding.finals false

      if report_params[:organization_ids].present?
        organization_ids = Array(report_params[:organization_ids]).reject(&:blank?)
        weaknesses       = weaknesses.where organization_id: organization_ids if organization_ids
      end

      weaknesses
    end

    def render_weaknesses_risk_map_csv
      render_or_send_by_mail(
        collection:  @weaknesses,
        filename:    "#{@title.downcase}.csv",
        method_name: :by_risk_map,
        options:     Hash(params[:weaknesses_risk_map]&.permit!).merge(
          {back_to_url: weaknesses_risk_map_follow_up_audit_path})
      )
    end
end
