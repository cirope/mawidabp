module Reports::PlannedCostSummary
  include Reports::Period
  include Reports::Pdf

  def planned_cost_summary
    init_planned_cost_summary_vars

    @periods.each do |period|
      plan_items_by_month = @plan_items.for_period(period).group_by do |plan_item|
        plan_item.start.beginning_of_month.to_date
      end

      @data[period] = {
        data:   planned_cost_summary_data_for(plan_items_by_month),
        months: plan_items_by_month.keys.sort
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
        ['month', 20],
        ['estimated_amount', 30],
        ['real_amount', 30],
        ['deviation', 20]
      ]
    end

    def planned_cost_summary_data_for plan_items_by_month
      data = {}

      Hash[plan_items_by_month.sort].each do |date, plan_items|
        planned  = ResourceUtilization.human.joins(:user).items_planned_on  plan_items
        executed = ResourceUtilization.human.joins(:user).items_executed_on plan_items

        put_planned_data_on   data, planned, date
        put_executed_data_on  data, executed, date
        put_deviation_data_on data, date
      end

      data
    end

    def put_planned_data_on data, planned, date
      planned.group(:resource_id, :name, :last_name).sum(:units).each do |user_data, sum|
        user_id = user_data.first

        data[user_id] ||= {
          name: [user_data.last, user_data.second].join(', '),
          data: {}
        }

        data[user_id][:data][date] = { planed_units: sum }
      end
    end

    def put_executed_data_on data, executed, date
      executed.group(:resource_id, :name, :last_name).sum(:units).each do |user_data, sum|
        user_id = user_data.first

        data[user_id] ||= {
          name: [user_data.last, user_data.second].join(', '),
          data: {}
        }

        data[user_id][:data][date] ||= {}
        data[user_id][:data][date][:executed_units] = sum
      end
    end

    def put_deviation_data_on data, date
      data.each do |user_id, user_data|
        if user_data[:data][date]
          estimated  = user_data[:data][date][:planed_units] || 0
          real       = user_data[:data][date][:executed_units] || 0
          difference = estimated - real
          deviation  = real > 0 ? difference / real.to_f * 100 : (estimated > 0 ? 100 : 0)

          user_data[:data][date][:deviation] = deviation
        end
      end
    end

    def put_planned_cost_summary_on pdf, period
      @data[period][:data].each do |user_id, data|
        pdf.text "<b>#{data[:name]}</b>", inline_format: true, font_size: PDF_FONT_SIZE
        pdf.move_down PDF_FONT_SIZE

        put_user_planned_cost_summary_on pdf, data[:data], @data[period][:months]

        pdf.move_down PDF_FONT_SIZE
      end
    end

    def put_user_planned_cost_summary_on pdf, data, months
      column_headers, column_widths = [], []
      table_data = user_planned_cost_summary_table_data data, months

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

    def user_planned_cost_summary_table_data data, months
      months.map do |month|
        month_data = data[month] || {}

        [
          I18n.l(month, format: '%b-%y'),
          '%.2f' % (month_data[:planed_units] || 0),
          '%.2f' % (month_data[:executed_units] || 0),
          '%.0f%%' % (month_data[:deviation] || 0)
        ]
      end
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
