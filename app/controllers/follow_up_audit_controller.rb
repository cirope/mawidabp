class FollowUpAuditController < ApplicationController
  include Reports::WeaknessesByState
  include Reports::WeaknessesByRisk
  include Reports::WeaknessesByAuditType
  include Reports::ControlObjectiveStats
  include Reports::ProcessControlStats
  include Reports::WeaknessesByRiskReport
  include Reports::FixedWeaknessesReport
  include Reports::NonconformitiesReport

  before_action :auth, :load_privileges, :check_privileges

  # Muestra una lista con los reportes disponibles
  #
  # * GET /follow_up_audit
  def index
    @title = t 'follow_up_audit.index_title'
    @quality_management = current_organization.kind.eql? 'quality_management'

    respond_to do |format|
      format.html
    end
  end

  # Crea un PDF con un análisis de costos para un determinado rango de fechas
  #
  # * GET /follow_up_committee/cost_analysis
  def cost_analysis
    @title = t 'follow_up_audit.cost_analysis_title'
    @from_date, @to_date = *make_date_range(params[:cost_analysis])
    @periods = periods_for_interval
    @column_order = [['business_unit', 20], ['project', 20], ['review', 10],
      ['audit_cost', 25], ['audited_cost', 25]]
    @weaknesses_data = {}
    @oportunities_data = {}

    @periods.each do |period|
      @weaknesses_data[period] ||= []
      @oportunities_data[period] ||= []
      total_weaknesses_audit_cost, total_weaknesses_audited_cost = 0, 0
      total_oportunities_audit_cost, total_oportunities_audited_cost = 0, 0
      weaknesses_by_review = Weakness.with_status_for_report.list_all_by_date(
        @from_date, @to_date, false).finals(false).for_period(period).group_by(
        &:review)
      oportunities_by_review = Oportunity.with_status_for_report.list_all_by_date(
        @from_date, @to_date, false).finals(false).for_period(period).group_by(
        &:review)

      unless weaknesses_by_review.blank?
        weaknesses_by_review.each do |review, weaknesses|
          audit_cost = weaknesses.inject(0) do |sum, weakness|
            sum + weakness.costs.audit.to_a.sum(&:cost)
          end
          audited_cost = weaknesses.inject(0) do |sum, weakness|
            sum + weakness.costs.audited.to_a.sum(&:cost)
          end

          total_weaknesses_audit_cost += audit_cost
          total_weaknesses_audited_cost += audited_cost
          @weaknesses_data[period] << [
            review.plan_item.business_unit.name,
            review.plan_item.project,
            review.identification,
            audit_cost.to_s,
            audited_cost.to_s
          ]
        end

        @weaknesses_data[period] << [
          '', '', '',
          "<b>#{total_weaknesses_audit_cost}</b>",
          "<b>#{total_weaknesses_audited_cost}</b>"
        ]
      end

      unless oportunities_by_review.blank?
        oportunities_by_review.each do |review, oportunities|
          audit_cost = oportunities.inject(0) do |sum, oportunity|
            sum + oportunity.costs.audit.to_a.sum(&:cost)
          end
          audited_cost = oportunities.inject(0) do |sum, oportunity|
            sum + oportunity.costs.audited.to_a.sum(&:cost)
          end

          total_oportunities_audit_cost += audit_cost
          total_oportunities_audited_cost += audited_cost
          @oportunities_data[period] << [
            review.plan_item.business_unit.name,
            review.plan_item.project,
            review.identification,
            audit_cost.to_s,
            audited_cost.to_s
          ]
        end

        @oportunities_data[period] << [
          '', '', '',
          "<b>#{total_oportunities_audit_cost}</b>",
          "<b>#{total_oportunities_audited_cost}</b>"
        ]
      end
    end
  end

  # Crea un PDF con un análisis de costos para un determinado rango de fechas
  #
  # * POST /follow_up_committee/create_cost_analysis
  def create_cost_analysis
    self.cost_analysis

    pdf = Prawn::Document.create_generic_pdf :landscape
    column_headers, column_widths = [], []

    @column_order.each do |column|
      column_headers <<
        "<b>#{t("follow_up_audit.cost_analysis.column_#{column.first}")}</b>"
      column_widths << pdf.percent_width(column.last)
    end

    pdf.add_generic_report_header current_organization
    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_description_item(
      t('follow_up_committee.period.title'),
      t('follow_up_committee.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    pdf.move_down PDF_FONT_SIZE

    @periods.each do |period|
      pdf.move_down PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :left
      pdf.move_down PDF_FONT_SIZE

      pdf.add_title "#{t('follow_up_audit.cost_analysis.weaknesses')}\n",
        PDF_FONT_SIZE, :center

      unless @weaknesses_data[period].blank?
        pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
          table_options = pdf.default_table_options(column_widths)

          pdf.table(@weaknesses_data[period].insert(0, column_headers), table_options) do
            row(0).style(
              :background_color => 'cccccc',
              :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
            )
          end
        end
      else
        pdf.text t('follow_up_audit.cost_analysis.without_weaknesses'),
          :font_size => PDF_FONT_SIZE
      end

      pdf.move_down PDF_FONT_SIZE

      pdf.add_title "#{t('follow_up_audit.cost_analysis.oportunities')}\n",
        PDF_FONT_SIZE, :center

      unless @oportunities_data[period].blank?
        pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
          table_options = pdf.default_table_options(column_widths)

          pdf.table(@oportunities_data[period].insert(0, column_headers), table_options) do
            row(0).style(
              :background_color => 'cccccc',
              :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
            )
          end
        end
      else
        pdf.text t('follow_up_audit.cost_analysis.without_oportunities'),
          :font_size => PDF_FONT_SIZE
      end
    end

    pdf.custom_save_as(
      t('follow_up_audit.cost_analysis.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'follow_up_cost_analysis',
      0)

    redirect_to Prawn::Document.relative_path(
      t('follow_up_audit.cost_analysis.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'follow_up_cost_analysis',
      0)
  end

  private
    def load_privileges #:nodoc:
      @action_privileges.update(
        :weaknesses_by_state => :read,
        :create_weaknesses_by_state => :read,
        :weaknesses_by_risk => :read,
        :create_weaknesses_by_risk => :read,
        :weaknesses_by_audit_type => :read,
        :create_weaknesses_by_audit_type => :read,
        :cost_analysis => :read,
        :create_cost_analysis => :read,
        :high_risk_weaknesses_report => :read,
        :create_high_risk_weaknesses_report => :read,
        :fixed_weaknesses_report => :read,
        :create_fixed_weaknesses_report => :read,
        :control_objective_stats => :read,
        :create_control_objective_stats => :read,
        :process_control_stats => :read,
        :create_process_control_stats => :read
      )
    end
end
