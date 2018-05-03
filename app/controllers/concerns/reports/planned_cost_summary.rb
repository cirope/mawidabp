module Reports::PlannedCostSummary
  include Reports::Period
  include Reports::PDF

  def planned_cost_summary
    init_planned_cost_summary_vars

    @periods.each do |period|
      items               = @plan_items.for_period period
      plan_items_by_month = items.each_with_object({}) do |plan_item, result|
        plan_item.month_beginnings.each do |month|
          result[month] ||= []
          result[month] <<  plan_item
        end
      end

      @data[period] = {
        data:   planned_cost_summary_data_for(plan_items_by_month),
        months: plan_items_by_month.keys.flatten.uniq.sort
      }
    end
  end

  def create_planned_cost_summary
    planned_cost_summary

    pdf = init_pdf params[:report_title], nil

    add_pdf_description pdf, 'conclusion', @from_date, @to_date

    @periods.each do |period|
      add_period_title pdf, period

      if @data[period].present? && @data[period][:data].present?
        put_planned_cost_summary_on pdf, period
      else
        pdf.text t('execution_reports.cost_analysis.without_audits_in_the_period'), font_size: PDF_FONT_SIZE
      end
    end

    save_and_redirect_to_planned_cost_summary_pdf pdf
  end

  private

    def init_planned_cost_summary_vars
      @title = t 'execution_reports.planned_cost_summary_title'
      @from_date, @to_date = *make_date_range(params[:planned_cost_summary])
      @data = {}
      @periods = periods_for_interval
      @plan_items = PlanItem.list.where(start: @from_date..@to_date)

      @column_order = [
        ['month', 35],
        ['estimated_amount', 65]
      ]
    end

    def planned_cost_summary_data_for plan_items_by_month
      data = {}

      Hash[plan_items_by_month.sort].each do |date, plan_items|
        plan_items.each do |plan_item|
          put_cost_summary_for data, date, plan_item
        end
      end

      data
    end

    def put_cost_summary_for data, date, plan_item
      spreads = plan_item.month_spreads

      plan_item.human_resource_utilizations.each do |hru|
        units = hru.units * spreads[date]

        data[hru.resource_id] ||= {
          name: hru.resource.full_name,
          total: 0,
          data: {}
        }

        data[hru.resource_id][:data][date] ||= { planned_units:  0 }

        data[hru.resource_id][:data][date][:planned_units] += units
        data[hru.resource_id][:total] += units
      end
    end

    def put_planned_cost_summary_on pdf, period
      @data[period][:data].each do |user_id, data|
        pdf.move_down PDF_FONT_SIZE
        pdf.text "<b>#{data[:name]}</b>", inline_format: true, font_size: PDF_FONT_SIZE
        pdf.move_down PDF_FONT_SIZE

        put_user_planned_cost_summary_on pdf,
          data: data[:data], months: @data[period][:months], total: data[:total]

        pdf.move_down PDF_FONT_SIZE
      end
    end

    def put_user_planned_cost_summary_on pdf, data:, months:, total:
      column_headers, column_widths = [], []
      table_data = user_planned_cost_summary_table_data data, months, total

      @column_order.each do |column|
        column_headers << "<b>#{t("execution_reports.planned_cost_summary.column_#{column.first}")}</b>"
        column_widths  << pdf.percent_width(column.last)
      end

      pdf.font_size (PDF_FONT_SIZE * 0.75).round do
        table_options = pdf.default_table_options column_widths

        pdf.table table_data.insert(0, column_headers), table_options do
          row(0).style(
            background_color: 'cccccc',
            padding: [
              (PDF_FONT_SIZE * 0.5).round,
              (PDF_FONT_SIZE * 0.3).round
            ]
          )
        end
      end
    end

    def user_planned_cost_summary_table_data data, months, total
      result = months.map do |month|
        month_data = data[month] || {}

        [
          I18n.l(month, format: '%b-%y'),
          '%.2f' % (month_data[:planned_units] || 0)
        ]
      end

      result << [
        "<b>#{I18n.t 'label.total'}</b>",
        "<b>#{'%.2f' % total}</b>"
      ]
    end

    def save_and_redirect_to_planned_cost_summary_pdf pdf
      title = t 'execution_reports.planned_cost_summary.pdf_name',
        from_date: @from_date.to_formatted_s(:db),
        to_date:   @to_date.to_formatted_s(:db)

      pdf.custom_save_as title, 'planned_cost_summary', 0

      @report_path = Prawn::Document.relative_path title, 'planned_cost_summary', 0

      respond_to do |format|
        format.html { redirect_to @report_path }
        format.js { render 'shared/pdf_report' }
      end
    end
end
