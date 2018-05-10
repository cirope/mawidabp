module Reports::FollowUpCostAnalysis
  include Reports::PDF

  def follow_up_cost_analysis
    init_follow_up_cost_vars

    @periods.each do |period|
      init_cost_analysis_period_vars(period)

      unless @weaknesses_by_review.blank?
        calculate_weaknesses_cost(period)
        add_weaknesses_data(period)
      end

      unless @oportunities_by_review.blank?
        calculate_oportunities_cost(period)
        add_oportunities_data(period)
      end
    end
  end

  def init_follow_up_cost_vars
    @title = t 'follow_up_audit.cost_analysis_title'
    @from_date, @to_date = *make_date_range(params[:follow_up_cost_analysis])
    @periods = periods_for_interval
    @column_order = [['business_unit', 20], ['project', 20], ['review', 10],
      ['audit_cost', 25], ['audited_cost', 25]]
    @weaknesses_data = {}
    @oportunities_data = {}
  end

  def init_cost_analysis_period_vars(period)
    @weaknesses_data[period] ||= []
    @oportunities_data[period] ||= []
    @total_weaknesses_audit_cost, @total_weaknesses_audited_cost = 0, 0
    @total_oportunities_audit_cost, @total_oportunities_audited_cost = 0, 0
    @weaknesses_by_review = Weakness.with_status_for_report.list_all_by_date(
      @from_date, @to_date, false).finals(false).for_period(period).group_by(
      &:review)
    @oportunities_by_review = Oportunity.with_status_for_report.list_all_by_date(
      @from_date, @to_date, false).finals(false).for_period(period).group_by(
      &:review)
  end

  def calculate_weaknesses_cost(period)
    @weaknesses_by_review.each do |review, weaknesses|
      audit_cost = weaknesses.inject(0) do |sum, weakness|
        sum + weakness.costs.audit.to_a.sum(&:cost)
      end
      audited_cost = weaknesses.inject(0) do |sum, weakness|
        sum + weakness.costs.audited.to_a.sum(&:cost)
      end

      @total_weaknesses_audit_cost += audit_cost
      @total_weaknesses_audited_cost += audited_cost
      @weaknesses_data[period] << [
        review.plan_item.business_unit.name,
        review.plan_item.project,
        review.identification,
        '%.2f' % audit_cost,
        '%.2f' % audited_cost
      ]
    end
  end

  def add_weaknesses_data(period)
    @weaknesses_data[period] << [
      '', '', '',
      "<b>#{@total_weaknesses_audit_cost}</b>",
      "<b>#{@total_weaknesses_audited_cost}</b>"
    ]
  end

  def calculate_oportunities_cost(period)
    @oportunities_by_review.each do |review, oportunities|
      audit_cost = oportunities.inject(0) do |sum, oportunity|
        sum + oportunity.costs.audit.to_a.sum(&:cost)
      end
      audited_cost = oportunities.inject(0) do |sum, oportunity|
        sum + oportunity.costs.audited.to_a.sum(&:cost)
      end

      @total_oportunities_audit_cost += audit_cost
      @total_oportunities_audited_cost += audited_cost
      @oportunities_data[period] << [
        review.plan_item.business_unit.name,
        review.plan_item.project,
        review.identification,
        '%.2f' % audit_cost,
        '%.2f' % audited_cost
      ]
    end
  end

  def add_oportunities_data(period)
    @oportunities_data[period] << [
      '', '', '',
      "<b>#{@total_oportunities_audit_cost}</b>",
      "<b>#{@total_oportunities_audited_cost}</b>"
    ]
  end
  # Crea un PDF con un análisis de costos para un determinado rango de fechas
  #
  # * POST /follow_up_committee/create_cost_analysis
  def create_follow_up_cost_analysis
    self.follow_up_cost_analysis

    pdf = init_pdf(params[:report_title], nil)
    add_pdf_description(pdf, 'follow_up', @from_date, @to_date)

    prepare_columns(pdf)
    pdf.move_down PDF_FONT_SIZE

    @periods.each do |period|
      add_period_title(pdf, period)
      add_weaknesses_table(pdf, period)
      add_oportunities_table(pdf, period)
    end

    save_pdf(pdf, 'follow_up', @from_date, @to_date, 'follow_up_cost_analysis')
    redirect_to_pdf('follow_up', @from_date, @to_date, 'follow_up_cost_analysis')
  end

  def prepare_columns(pdf)
    @column_headers, @column_widths = [], []

    @column_order.each do |column|
      @column_headers <<
        "<b>#{t("follow_up_audit.cost_analysis.column_#{column.first}")}</b>"
      @column_widths << pdf.percent_width(column.last)
    end
  end

  def add_weaknesses_table(pdf, period)
    pdf.add_title "#{t('follow_up_audit.cost_analysis.weaknesses')}\n",
      PDF_FONT_SIZE, :center

    unless @weaknesses_data[period].blank?
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(@column_widths)

        pdf.table(@weaknesses_data[period].insert(0, @column_headers), table_options) do
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
  end

  def add_oportunities_table(pdf, period)
    pdf.add_title "#{t('follow_up_audit.cost_analysis.oportunities')}\n",
      PDF_FONT_SIZE, :center

    unless @oportunities_data[period].blank?
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(@column_widths)

        pdf.table(@oportunities_data[period].insert(0, @column_headers), table_options) do
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
end
