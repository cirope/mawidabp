module Reports::DetailedManagement
  include Reports::Pdf

  def detailed_management_report
    init_vars

    raw_reviews = find_reviews

    raw_reviews.each do |period, reviews|
      audits_by_business_unit = []

      BusinessUnitType.list.each do |but|
        set_columns(but.business_unit_label)

        reviews.each do |r|
          if r.business_unit.business_unit_type_id == but.id
            process_controls = get_review_process_controls(r)

            group_findings_data(r)

            @column_data << [
              r.business_unit.name,
              r.to_s,
              process_controls,
              @risk_levels.blank? ?
                t('execution_reports.detailed_management_report.without_weaknesses') :
                @weaknesses_count_text,
              @sqm ? @nonconformities_count_text : @oportunities_count_text
            ]
          end
        end

        audits_by_business_unit << {
          name: but.name,
          external: but.external,
          columns: @columns,
          column_data: @column_data
        }
      end

      @audits_by_period << {
        period: period,
        audits_by_business_unit: audits_by_business_unit
      }
    end
  end

  def init_vars
    @title = t 'execution_reports.detailed_management_report_title'
    @from_date, @to_date = *make_date_range(params[:detailed_management_report])
    @sqm = current_organization.kind.eql? 'quality_management'
    @column_order = ['business_unit_report_name', 'review', 'process_control',
      'weaknesses_count']
    @column_order << (@sqm ? 'nonconformities_count' : 'oportunities_count')
    @risk_levels = []
    @audits_by_period = []
  end

  def find_reviews
    Review.includes(
        { control_objective_items: :control_objective },
        { plan_item: :business_unit }
      ).list_all_without_final_review_by_date(@from_date, @to_date
    ).group_by(&:period)
  end

  def set_columns(but_label)
    @column_data = []

    @columns = {
      'business_unit_report_name' => [but_label, 15],
      'review' => [Review.model_name.human, 16],
      'process_control' => ["#{BestPractice.human_attribute_name('process_controls.name')}", 45],
      'weaknesses_count' => ["#{t('review.weaknesses_count')} (1)", 12]
    }
    if @sqm
      @columns['nonconformities_count'] = ["#{t('review.nonconformities_count')} (2)", 12]
    else
      @columns['oportunities_count'] = ["#{t('review.oportunities_count')} (2)", 12]
    end
  end

  def get_review_process_controls(review)
    process_controls = []

    review.control_objective_items.each do |coi|                                                                                                                                           unless process_controls.include?(coi.process_control.name)
        process_controls << coi.process_control.name
      end
    end

    process_controls
  end

  def group_findings_data(review)
    weaknesses_count = {}

    review.weaknesses.each do |w|
      @risk_levels |= w.class.risks.sort{|r1, r2| r2[1] <=> r1[1]}.map(&:first)

      weaknesses_count[w.risk_text] ||= 0
      weaknesses_count[w.risk_text] += 1
    end

    @weaknesses_count_text =
      if weaknesses_count.values.sum == 0
        t('execution_reports.detailed_management_report.without_weaknesses')
      else
        @risk_levels.map do |risk|
          risk_text = t("risk_types.#{risk}")
          "#{risk_text}: #{weaknesses_count[risk_text] || 0}"
        end
      end
    if @sqm
      @nonconformities_count_text = review.nonconformities.count > 0 ?
        review.nonconformities.count.to_s :
        t('execution_reports.detailed_management_report.without_nonconformities')
    else
      @oportunities_count_text = review.oportunities.count > 0 ?
        review.oportunities.count.to_s :
        t('execution_reports.detailed_management_report.without_oportunities')
    end
  end

  def create_detailed_management_report
    self.detailed_management_report

    pdf = init_pdf(params[:report_title], params[:report_subtitle])

    pdf.text '<i>%s</i>' %
      t('execution_reports.detailed_management_report.clarification'),
      font_size: PDF_FONT_SIZE, inline_format: true

    pdf.move_down PDF_FONT_SIZE

    add_pdf_description(pdf, 'conclusion', @from_date, @to_date)

    @audits_by_period.each do |audit_by_period|
      add_period_title(pdf, audit_by_period[:period])

      audit_by_period[:audits_by_business_unit].each do |data|
        prepare_pdf_table_headers(pdf, data)

        add_pdf_title(pdf, data)

        pdf.add_subtitle data[:name], PDF_FONT_SIZE, PDF_FONT_SIZE

        prepare_pdf_table_rows(data)

        unless @column_data.blank?
          add_pdf_table(pdf)
        else
          pdf.text(
            t('execution_reports.detailed_management_report.without_audits_in_the_period'),
            style: :italic)
        end
      end
    end

    if @audits_by_period.empty?
      pdf.move_down PDF_FONT_SIZE
      pdf.text(
        t('execution_reports.detailed_management_report.without_audits_in_the_interval'))
    end

    add_report_references(pdf)

    save_and_redirect_to_pdf(pdf)
  end

  def prepare_pdf_table_headers(pdf, data)
    @column_data, @column_headers, @column_widths = [], [], []

    @column_order.each do |col_name|
      @column_headers << "<b>#{data[:columns][col_name].first}</b>"
      @column_widths << pdf.percent_width(data[:columns][col_name].last)
    end
  end

  def prepare_pdf_table_rows(data)
    data[:column_data].each do |row|
      new_row = []

      row.each do |column_content|
        new_row << (column_content.kind_of?(Array) ?
          column_content.map {|l| " • #{l}"}.join("\n") :
          column_content)
      end

      @column_data << new_row
    end
  end

  def add_pdf_table(pdf)
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

  def save_and_redirect_to_pdf(pdf)
    pdf.custom_save_as(
      t('execution_reports.detailed_management_report.pdf_name',
        from_date: @from_date.to_formatted_s(:db),
        to_date: @to_date.to_formatted_s(:db)),
      'detailed_management_report', 0)

    @report_path = Prawn::Document.relative_path(
      t('execution_reports.detailed_management_report.pdf_name',
      from_date: @from_date.to_formatted_s(:db),
      to_date: @to_date.to_formatted_s(:db)),
      'detailed_management_report', 0
    )

    respond_to do |format|
      format.html { redirect_to @report_path }
      format.js { render 'shared/pdf_report' }
    end
  end

  def add_report_references(pdf)
    pdf.move_down PDF_FONT_SIZE
    if @sqm
      pdf.text t('execution_reports.detailed_management_report.sqm_references'),
        font_size: (PDF_FONT_SIZE * 0.75).round, justification: :full
    else
      pdf.text t('execution_reports.detailed_management_report.references',
        risk_types: @risk_levels.to_sentence),
        font_size: (PDF_FONT_SIZE * 0.75).round, justification: :full
    end
  end

  def add_pdf_title(pdf, data)
   if !data[:external] && !@internal_title_showed
      title = t 'execution_reports.detailed_management_report.internal_audit_weaknesses'
      @internal_title_showed = true
    elsif data[:external] && !@external_title_showed
      title = t 'execution_reports.detailed_management_report.external_audit_weaknesses'
      @external_title_showed = true
    end

    if title
      pdf.move_down PDF_FONT_SIZE
      pdf.add_title title, (PDF_FONT_SIZE * 1.25).round, :center
    end
  end
end
