module Reports::CostAnalysis
  include Reports::Pdf

  def cost_analysis
    init_cost_vars

    @periods.each do |period|
      @total_estimated_amount = 0
      @total_real_amount = 0

      @conclusion_reviews.for_period(period).each do |cr|
        calculate_total_cost_data(cr, period)

        unless params[:include_details].blank?
          @data = {:review => cr.review, :data => []}

          set_estimated_data(cr)
          set_real_data

          @detailed_data[period] ||= []

          unless @data[:data].empty?
            @detailed_data[period] << @data
          end
        end
      end

      set_total_costs(period)
    end
  end

  def init_cost_vars
    @title = t(params[:include_details].blank? ?
      'conclusion_audit_report.cost_analysis_title' :
      'conclusion_audit_report.detailed_cost_analysis_title')
    @from_date, @to_date = *make_date_range(params[:cost_analysis])
    @periods = periods_for_interval
    @column_order = [['business_unit', 20], ['review', 35],
      ['estimated_amount', 15], ['real_amount', 15], ['deviation', 15]]
    @detailed_column_order = [['resource', 55], ['estimated_amount', 15],
      ['real_amount', 15], ['deviation', 15]]
    @total_cost_data = {}
    @detailed_data = {}
    @currency_mask = "#{I18n.t('number.currency.format.unit')}%.2f"
    @conclusion_reviews = ConclusionFinalReview.list_all_by_date(@from_date,
      @to_date)
  end

  def calculate_total_cost_data(conclusion_review, period)
    estimated_amount = conclusion_review.review.plan_item.cost
    real_amount = conclusion_review.review.workflow.try(:cost) || 0
    amount_difference = estimated_amount - real_amount
    deviation = real_amount > 0 ? amount_difference / real_amount.to_f * 100 :
      (estimated_amount > 0 ? 100 : 0)
    deviation_text =
      "%.2f%% (#{@currency_mask % amount_difference.abs})" % deviation
    @total_estimated_amount += estimated_amount
    @total_real_amount += real_amount
  
    set_total_cost_data(conclusion_review, period, estimated_amount, real_amount, deviation_text)
  end

  def set_estimated_data(conclusion_review)
    estimated_resources =
      conclusion_review.review.plan_item.resource_utilizations.group_by(&:resource)
    @real_resources = conclusion_review.review.workflow ?
      conclusion_review.review.workflow.resource_utilizations.group_by(&:resource) : {}

    set_estimated_resources_data(estimated_resources)
  end

  def set_real_data
    @real_resources.each do |resource, real_utilizations|
      real_amount = real_utilizations.sum(&:cost)

      @data[:data] << [
        resource.resource_name,
        (@currency_mask % 0),
        (@currency_mask % real_amount),
        "-100.00% (#{@currency_mask % real_amount})"
      ]
    end
  end

  def set_total_costs(period)
    total_difference_amount = @total_estimated_amount - @total_real_amount
    total_deviation = @total_real_amount > 0 ?
      total_difference_amount / @total_real_amount.to_f * 100 :
      (@total_estimated_amount > 0 ? 100 : 0)
    total_deviation_mask =
      "%.2f%% (#{@currency_mask % total_difference_amount.abs})"

    @total_cost_data[period] ||= []
    @total_cost_data[period] << [
      '',
      '',
      "<b>#{@currency_mask % @total_estimated_amount}</b>",
      "<b>#{@currency_mask % @total_real_amount}</b>",
      "<b>#{total_deviation_mask % total_deviation}</b>"
    ]
  end

  def set_total_cost_data(conclusion_review, period, estimated_amount, real_amount, deviation_text)
    @total_cost_data[period] ||= []
    @total_cost_data[period] << [
      conclusion_review.review.business_unit.name,
      conclusion_review.review.to_s,
      @currency_mask % estimated_amount,
      @currency_mask % real_amount,
      deviation_text
    ]
  end

  def create_cost_analysis
    self.cost_analysis

    pdf = init_pdf(params[:report_title], nil)

    add_pdf_description(pdf, 'conclusion', @from_date, @to_date)

    @periods.each do |period|
      add_period_title(pdf, period)
      @column_headers, @column_widths = [], []
      unless @total_cost_data[period].blank?
        set_cost_analysis_columns(pdf)
        add_total_cost_table(pdf, period)
      else
        pdf.text(
          t('conclusion_audit_report.cost_analysis.without_audits_in_the_period'),
            :font_size => PDF_FONT_SIZE)
      end

      unless @detailed_data[period].blank?
        set_detailed_columns(pdf)
        add_detailed_table(pdf, period)
      end
    end

    save_and_redirect_to_pdf(pdf)
  end

  def save_and_redirect_to_pdf(pdf)
    pdf.custom_save_as(
      t('conclusion_audit_report.cost_analysis.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'cost_analysis', 0)

    @report_path = Prawn::Document.relative_path(
      t('conclusion_audit_report.cost_analysis.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'cost_analysis', 0)

    respond_to do |format|
      format.html { redirect_to @report_path }
      format.js { render 'shared/pdf_report' }
    end
  end

  def set_cost_analysis_columns(pdf)
    @column_order.each do |column|
      @column_headers <<
        "<b>#{t("conclusion_audit_report.cost_analysis.general_column_#{column.first}")}</b>"
      @column_widths << pdf.percent_width(column.last)
    end

    pdf.move_down PDF_FONT_SIZE
  end

  def add_total_cost_table(pdf, period)
    pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
      table_options = pdf.default_table_options(@column_widths)

      pdf.table(@total_cost_data[period].insert(0, @column_headers), table_options) do
        row(0).style(
          :background_color => 'cccccc',
          :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
        )
      end
    end
  end

  def set_estimated_resources_data(estimated_resources)
    estimated_resources.each do |resource, estimated_utilizations|
      real_utilizations = @real_resources.delete(resource) || []
      estimated_amount = estimated_utilizations.sum(&:cost)
      real_amount = real_utilizations.sum(&:cost)
      amount_difference = estimated_amount - real_amount
      deviation = real_amount > 0 ?
        amount_difference / real_amount.to_f * 100 :
        (estimated_amount > 0 ? 100 : 0)
      deviation_text =
        "%.2f%% (#{@currency_mask % amount_difference.abs})" % deviation

      @data[:data] << [
        resource.resource_name,
        @currency_mask % estimated_amount,
        @currency_mask % real_amount,
        deviation_text
      ]                                                                                                                                                                               
    end
  end

  def set_detailed_columns(pdf)
    @detailed_columns = {}
    @column_headers, @column_widths = [], []
    @detailed_column_order.each do |col_name, col_width|
      @column_headers <<
        "<b>#{t("conclusion_audit_report.cost_analysis.detailed_column_#{col_name}")}</b>"
      @column_widths << pdf.percent_width(col_width)
    end
  end

  def add_detailed_table(pdf, period)
    @detailed_data[period].each do |detailed_data|
      pdf.text "\n<b>#{detailed_data[:review]}</b>\n\n",
        :font_size => PDF_FONT_SIZE, :inline_format => true

      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(@column_widths)

        pdf.table(detailed_data[:data].insert(0, @column_headers), table_options) do
          row(0).style(
            :background_color => 'cccccc',
            :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end
  end
end
