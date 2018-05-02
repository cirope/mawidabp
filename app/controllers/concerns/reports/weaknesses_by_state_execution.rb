module Reports::WeaknessesByStateExecution
  include Reports::PDF

  def weaknesses_by_state_execution
    init_instance_vars

    @reviews.each do |period, reviews|
      group_findings_by_state(reviews)

      @counts << { period: period, counts: @count_for_period }
    end
  end

  def init_instance_vars
    @title = t 'execution_reports.weaknesses_by_state_title'
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_state_execution])
    @audit_types = [:internal, :external]
    @counts = []
    @status = Finding::STATUS.except(:repeated, :revoked).sort do |s1, s2|
      s1.last <=> s2.last
    end
    @reviews = Review.list_all_without_final_review_by_date(
      @from_date, @to_date).group_by(&:period)
  end

  def group_findings_by_state(reviews)
    @count_for_period = {}

    @audit_types.each do |audit_type|
      reviews.select(&:"#{audit_type}_audit?").each do |review|
        @count_for_period[audit_type] ||= {}
        @count_for_period[audit_type][review] ||= {}
        @count_for_period[audit_type][review][:weaknesses] =
          review.weaknesses.group(:state).count
        @count_for_period[audit_type][review][:oportunities] =
          review.oportunities.group(:state).count
      end
    end
  end

  def create_weaknesses_by_state_execution
    self.weaknesses_by_state_execution

    pdf = init_pdf(params[:report_title], nil)

    pdf.text '<i>%s</i>' %
      t('execution_reports.weaknesses_by_state.clarification'),
        font_size: PDF_FONT_SIZE, inline_format: true

    pdf.move_down PDF_FONT_SIZE
    add_pdf_description(pdf, 'conclusion', @from_date, @to_date)

    @counts.each do |count_data|
      add_period_title(pdf, count_data[:period], :justify)

      @audit_types.each do |type|
        pdf.move_down PDF_FONT_SIZE
        pdf.add_title t("execution_reports.findings_type_#{type}"),
          (PDF_FONT_SIZE * 1.25).round, :center

        if count_data[:counts][type]
          count_data[:counts][type].each do |review, counts|
            count_findings(counts)

            pdf.text "\n<b>#{Review.model_name.human}</b>: #{review}\n\n",
              font_size: PDF_FONT_SIZE, inline_format: true

            unless @totals == 0
              set_column_data(type, pdf)
              count_findings_by_state(type)
              set_finding_totals(type)
              add_weaknesses_by_state_pdf_table(pdf)
            else
              pdf.text t('execution_reports.without_findings'), font_size: PDF_FONT_SIZE, style: :italic
              pdf.move_down PDF_FONT_SIZE
            end
          end
        else
          pdf.text t('execution_reports.without_weaknesses'), font_size: PDF_FONT_SIZE, style: :italic
        end
      end
    end

    if @counts.empty?
      pdf.move_down PDF_FONT_SIZE
      pdf.text t('execution_reports.without_weaknesses_in_the_interval'),
        font_size: PDF_FONT_SIZE
    end

    save_and_redirect_pdf(pdf)
  end

  def set_column_data(type, pdf)
    @columns = [
      [Finding.human_attribute_name('state'), 20],
      [
        t('execution_reports.weaknesses_by_state.weaknesses_column'),
        20]
    ]
    @column_data, @column_headers, @column_widths = [], [], []

    if type == :internal
      @columns << [t('execution_reports.weaknesses_by_state.oportunities_column'), 20]
    end

    @columns.each do |col_data|
      @column_headers << "<b>#{col_data.first}</b>"
      @column_widths << pdf.percent_width(col_data.last)
    end
  end

  def count_findings(counts)
    @weaknesses_count = counts[:weaknesses]
    @oportunities_count = counts[:oportunities]
    @total_weaknesses = @weaknesses_count.values.sum
    @total_oportunities = @oportunities_count.values.sum

    @totals = @total_weaknesses + @total_oportunities
  end

  def count_findings_by_state(type)
    @status.each do |state|
      w_count = @weaknesses_count[state.last] || 0
      o_count = @oportunities_count[state.last] || 0
      weaknesses_percentage = @total_weaknesses > 0 ?
        w_count.to_f / @total_weaknesses * 100 : 0.0
      oportunities_percentage = @total_oportunities > 0 ?
        o_count.to_f / @total_oportunities * 100 : 0.0

      @column_data << [
        t("findings.state.#{state.first}"),
        "#{w_count} (#{'%.2f' % weaknesses_percentage.round(2)}%)"
      ]

      if type == :internal
        @column_data.last << "#{o_count} (#{'%.2f' % oportunities_percentage.round(2)}%)"
      end
    end
  end

  def set_finding_totals(type)
    @column_data << [
      "<b>#{t('execution_reports.weaknesses_by_state.total')}</b>",
      "<b>#{@total_weaknesses}</b>"
    ]

    if type == :internal
      @column_data.last << "<b>#{@total_oportunities}</b>"
    end
  end

  def save_and_redirect_pdf(pdf)
    pdf.custom_save_as(
      t('execution_reports.weaknesses_by_state.pdf_name',
        from_date: @from_date.to_formatted_s(:db),
        to_date: @to_date.to_formatted_s(:db)),
      'execution_weaknesses_by_state', 0)

    @report_path = Prawn::Document.relative_path(
      t('execution_reports.weaknesses_by_state.pdf_name',
        from_date: @from_date.to_formatted_s(:db),
        to_date: @to_date.to_formatted_s(:db)),
      'execution_weaknesses_by_state', 0)

    respond_to do |format|
      format.html { redirect_to @report_path }
      format.js { render 'shared/pdf_report' }
    end
  end

  def add_weaknesses_by_state_pdf_table(pdf)
    unless @column_data.blank?
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(@column_widths)

        pdf.table(@column_data.insert(0, @column_headers), table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end
  end
end
