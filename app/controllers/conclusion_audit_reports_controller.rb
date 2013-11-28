class ConclusionAuditReportsController < ApplicationController
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
  # * GET /conclusion_audit_reports
  def index
    @title = t('conclusion_audit_report.index_title')
    @quality_management = current_organization.kind.eql? 'quality_management'

    respond_to do |format|
      format.html
    end
  end

  def cost_analysis
    @title = t(params[:include_details].blank? ?
      'conclusion_audit_report.cost_analysis_title' :
      'conclusion_audit_report.detailed_cost_analysis_title')
    @from_date, @to_date = *make_date_range(params[:cost_analysis])
    @periods = periods_for_interval
    @column_order = [['business_unit', 20], ['review', 35],
      ['estimated_amount', 15], ['real_amount', 15],  ['deviation', 15]]
    @detailed_column_order = [['resource', 55], ['estimated_amount', 15],
      ['real_amount', 15], ['deviation', 15]]
    @total_cost_data = {}
    @detailed_data = {}
    currency_mask = "#{I18n.t('number.currency.format.unit')}%.2f"
    conclusion_reviews = ConclusionFinalReview.list_all_by_date(@from_date,
      @to_date)

    @periods.each do |period|
      total_estimated_amount = 0
      total_real_amount = 0

      conclusion_reviews.for_period(period).each do |cr|
        estimated_amount = cr.review.plan_item.cost
        real_amount = cr.review.workflow.try(:cost) || 0
        amount_difference = estimated_amount - real_amount
        deviation = real_amount > 0 ? amount_difference / real_amount.to_f * 100 :
          (estimated_amount > 0 ? 100 : 0)
        deviation_text =
          "%.2f%% (#{currency_mask % amount_difference.abs})" % deviation
        total_estimated_amount += estimated_amount
        total_real_amount += real_amount

        @total_cost_data[period] ||= []
        @total_cost_data[period] << [
          cr.review.business_unit.name,
          cr.review.to_s,
          currency_mask % estimated_amount,
          currency_mask % real_amount,
          deviation_text
       ]

        unless params[:include_details].blank?
          detailed_data = {:review => cr.review, :data => []}
          estimated_resources =
            cr.review.plan_item.resource_utilizations.group_by(&:resource)
          real_resources = cr.review.workflow ?
            cr.review.workflow.resource_utilizations.group_by(&:resource) : {}

          estimated_resources.each do |resource, estimated_utilizations|
            real_utilizations = real_resources.delete(resource) || []
            estimated_amount = estimated_utilizations.sum(&:cost)
            real_amount = real_utilizations.sum(&:cost)
            amount_difference = estimated_amount - real_amount
            deviation = real_amount > 0 ?
              amount_difference / real_amount.to_f * 100 :
              (estimated_amount > 0 ? 100 : 0)
            deviation_text =
              "%.2f%% (#{currency_mask % amount_difference.abs})" % deviation

            detailed_data[:data] << [
              resource.resource_name,
              currency_mask % estimated_amount,
              currency_mask % real_amount,
              deviation_text
            ]
          end

          real_resources.each do |resource, real_utilizations|
            real_amount = real_utilizations.sum(&:cost)

            detailed_data[:data] << [
              resource.resource_name,
              (currency_mask % 0),
              (currency_mask % real_amount),
              "-100.00% (#{currency_mask % real_amount})"
            ]
          end

          @detailed_data[period] ||= []

          unless detailed_data[:data].empty?
            @detailed_data[period] << detailed_data
          end
        end
      end

      total_difference_amount = total_estimated_amount - total_real_amount
      total_deviation = total_real_amount > 0 ?
        total_difference_amount / total_real_amount.to_f * 100 :
        (total_estimated_amount > 0 ? 100 : 0)
      total_deviation_mask =
        "%.2f%% (#{currency_mask % total_difference_amount.abs})"

      @total_cost_data[period] ||= []
      @total_cost_data[period] << [
        '',
        '',
        "<b>#{currency_mask % total_estimated_amount}</b>",
        "<b>#{currency_mask % total_real_amount}</b>",
        "<b>#{total_deviation_mask % total_deviation}</b>"
      ]
    end
  end

  def create_cost_analysis
    self.cost_analysis

    pdf = Prawn::Document.create_generic_pdf :landscape
    columns = {}

    pdf.add_generic_report_header current_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_description_item(
      t('conclusion_committee_report.period.title'),
      t('conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_down PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :left

      column_headers, column_widths = [], []

      unless @total_cost_data[period].blank?
        @column_order.each do |column|
          column_headers <<
            "<b>#{t("conclusion_audit_report.cost_analysis.general_column_#{column.first}")}</b>"
          column_widths << pdf.percent_width(column.last)
        end

        pdf.move_down PDF_FONT_SIZE

        pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
          table_options = pdf.default_table_options(column_widths)

          pdf.table(@total_cost_data[period].insert(0, column_headers), table_options) do
            row(0).style(
              :background_color => 'cccccc',
              :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
            )
          end
        end
      else
        pdf.text(
          t('conclusion_audit_report.cost_analysis.without_audits_in_the_period'),
          :font_size => PDF_FONT_SIZE)
      end

      unless @detailed_data[period].blank?
        detailed_columns = {}
        column_headers, column_widths = [], []
        @detailed_column_order.each do |col_name, col_width|
            column_headers <<
              "<b>#{t("conclusion_audit_report.cost_analysis.detailed_column_#{col_name}")}</b>"
            column_widths << pdf.percent_width(col_width)
        end

        @detailed_data[period].each do |detailed_data|
          pdf.text "\n<b>#{detailed_data[:review]}</b>\n\n",
            :font_size => PDF_FONT_SIZE, :inline_format => true

          pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
            table_options = pdf.default_table_options(column_widths)

            pdf.table(detailed_data[:data].insert(0, column_headers), table_options) do
              row(0).style(
                :background_color => 'cccccc',
                :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
              )
            end
          end
        end
      end
    end

    pdf.custom_save_as(
      t('conclusion_audit_report.cost_analysis.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'cost_analysis', 0)

    redirect_to Prawn::Document.relative_path(
      t('conclusion_audit_report.cost_analysis.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'cost_analysis', 0)
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
