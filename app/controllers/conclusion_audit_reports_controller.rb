require 'modules/conclusion_reports/conclusion_common_reports'
require 'modules/conclusion_reports/conclusion_high_risk_reports'

class ConclusionAuditReportsController < ApplicationController
  include ConclusionCommonReports
  include ConclusionHighRiskReports
  
  before_filter :auth, :load_privileges, :check_privileges
  hide_action :load_privileges, :add_weaknesses_synthesis_table,
    :get_weaknesses_synthesis_table_data, :make_date_range

  # Muestra una lista con los reportes disponibles
  #
  # * GET /conclusion_audit_reports
  def index
    @title = t('conclusion_audit_reports.index_title')

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
        @total_cost_data[period] << {
          'business_unit' => cr.review.business_unit.name.to_iso,
          'review' => cr.review.to_s.to_iso,
          'estimated_amount' => currency_mask % estimated_amount,
          'real_amount' => currency_mask % real_amount,
          'deviation' => deviation_text
        }

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

            detailed_data[:data] << {
              'resource' => resource.resource_name.to_iso,
              'estimated_amount' => currency_mask % estimated_amount,
              'real_amount' => currency_mask % real_amount,
              'deviation' => deviation_text
            }
          end

          real_resources.each do |resource, real_utilizations|
            real_amount = real_utilizations.sum(&:cost)

            detailed_data[:data] << {
              'resource' => resource.resource_name.to_iso,
              'estimated_amount' => currency_mask % 0,
              'real_amount' => currency_mask % real_amount,
              'deviation' => "-100.00% (#{currency_mask % real_amount})"
            }
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
      @total_cost_data[period] << {
        'business_unit' => '',
        'review' => '',
        'estimated_amount' => "<b>#{currency_mask % total_estimated_amount}</b>",
        'real_amount' => "<b>#{currency_mask % total_real_amount}</b>",
        'deviation' => "<b>#{total_deviation_mask % total_deviation}</b>"
      }
    end
  end

  def create_cost_analysis
    self.cost_analysis

    pdf = PDF::Writer.create_generic_pdf :landscape
    columns = {}

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE

    pdf.add_description_item(
      t('conclusion_committee_report.period.title'),
      t('conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :justify
      
      unless @total_cost_data[period].blank?
        @column_order.each do |col_name, col_width|
          columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |column|
            column.heading =
              t "conclusion_audit_report.cost_analysis.general_column_#{col_name}"
            column.width = pdf.percent_width col_width
          end
        end

        pdf.move_pointer PDF_FONT_SIZE

        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = @total_cost_data[period]
          table.column_order = @column_order.map(&:first)
          table.split_rows = true
          table.row_gap = PDF_FONT_SIZE
          table.font_size = (PDF_FONT_SIZE * 0.75).round
          table.shade_color = Color::RGB.from_percentage(95, 95, 95)
          table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
          table.heading_font_size = PDF_FONT_SIZE
          table.shade_headings = true
          table.position = :left
          table.orientation = :right
          table.render_on pdf
        end
      else
        pdf.text(
          t('conclusion_audit_report.cost_analysis.without_audits_in_the_period'),
          :font_size => PDF_FONT_SIZE)
      end

      unless @detailed_data[period].blank?
        detailed_columns = {}

        @detailed_column_order.each do |col_name, col_width|
          detailed_columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |column|
            column.heading =
              t "conclusion_audit_report.cost_analysis.detailed_column_#{col_name}"
            column.width = pdf.percent_width col_width
          end
        end

        @detailed_data[period].each do |detailed_data|
          pdf.text "\n<b>#{detailed_data[:review]}</b>\n\n",
            :font_size => PDF_FONT_SIZE

          PDF::SimpleTable.new do |table|
            table.width = pdf.page_usable_width
            table.columns = detailed_columns
            table.data = detailed_data[:data]
            table.column_order = @detailed_column_order.map(&:first)
            table.split_rows = true
            table.font_size = (PDF_FONT_SIZE * 0.75).round
            table.shade_color = Color::RGB.from_percentage(95, 95, 95)
            table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
            table.heading_font_size = PDF_FONT_SIZE
            table.shade_headings = true
            table.position = :left
            table.orientation = :right
            table.render_on pdf
          end
        end
      end
    end

    pdf.custom_save_as(
      t('conclusion_audit_report.cost_analysis.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'cost_analysis', 0)

    redirect_to PDF::Writer.relative_path(
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
      :create_control_objective_stats => :read
    )
  end
end