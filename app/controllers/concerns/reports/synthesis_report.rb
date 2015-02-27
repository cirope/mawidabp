module Reports::SynthesisReport
  include Reports::Pdf
  include Parameters::Risk

  def synthesis_report
    init_synthesis_vars

    if params[:synthesis_report]
      business_unit_type_reviews if params[:synthesis_report][:business_unit_type].present?
      business_unit_reviews if params[:synthesis_report][:business_unit].present?
    end

    @business_unit_types = @selected_business_unit ?
      [@selected_business_unit] : BusinessUnitType.list

    @periods.each do |period|
      @business_unit_types.each do |but|
        set_columns(but)
        init_business_unit_type_vars

        @conclusion_reviews.for_period(period).each do |c_r|
          if c_r.review.business_unit.business_unit_type_id == but.id
            set_process_controls_data(c_r)
            count_weaknesses(c_r)
            set_column_data(c_r)
          end
        end

        sort_column_data
        set_audits_by_business_unit_data(period, but)
      end
    end
  end

  def init_synthesis_vars
    @controller = params[:controller_name]
    @title = t("#{@controller}_committee_report.synthesis_report_title")
    @from_date, @to_date = *make_date_range(params[:synthesis_report])
    @periods = periods_for_interval
    @sqm = current_organization.kind.eql? 'quality_management'
    @column_order = ['business_unit_report_name', 'review', 'score',
        'process_control', 'weaknesses_count']
    @column_order << (@sqm ? 'nonconformities_count' : 'oportunities_count')
    @filters = []
    @risk_levels = []
    @audits_by_business_unit = {}
    @conclusion_reviews = ConclusionFinalReview.list_all_by_date(@from_date,
      @to_date)
  end

  def business_unit_type_reviews
    @selected_business_unit = BusinessUnitType.find(
      params[:synthesis_report][:business_unit_type])
    @conclusion_reviews = @conclusion_reviews.by_business_unit_type(
      @selected_business_unit.id)
    @filters << "<b>#{BusinessUnitType.model_name.human}</b> = " +
      "\"#{@selected_business_unit.name.strip}\""
  end

  def business_unit_reviews
    business_units = params[:synthesis_report][:business_unit].split(
      SPLIT_AND_TERMS_REGEXP
    ).uniq.map(&:strip)

    unless business_units.empty?
      @conclusion_reviews = @conclusion_reviews.by_business_unit_names(
        *business_units)
      @filters << "<b>#{BusinessUnit.model_name.human}</b> = " +
        "\"#{params[:synthesis_report][:business_unit].strip}\""
    end
  end

  def set_columns(but)
    @columns = {'business_unit_report_name' => [but.business_unit_label, 15],
      'review' => [Review.model_name.human, 16],
      'score' => ["#{Review.human_attribute_name(:score)} (1)", 15],
      'process_control' => ["#{BestPractice.human_attribute_name('process_controls.name')} (2)", 30],
      'weaknesses_count' => ["#{t('review.weaknesses_count')} (3)", 12]
    }
    if @sqm
      @columns['nonconformities_count'] = ["#{t('review.nonconformities_count')} (4)", 12]
    else
      @columns['oportunities_count'] = ["#{t('review.oportunities_count')} (4)", 12]
    end
  end

  def init_business_unit_type_vars
    @column_data = []
    @review_scores = []
    @repeated_count = 0 if @controller.eql? 'follow_up'
  end

  def set_process_controls_data(c_r)
    @process_controls = {}

    c_r.review.control_objective_items_for_score.each do |coi|
      @process_controls[coi.process_control.name] ||= []
      @process_controls[coi.process_control.name] << coi
    end

    @process_controls.each do |pc, control_objective_items|
      coi_count = control_objective_items.inject(0.0) do |acc, coi|
        acc + (coi.relevance || 0)
      end
      total = control_objective_items.inject(0.0) do |acc, coi|
        acc + coi.effectiveness * (coi.relevance || 0)
      end

      @process_controls[pc] = coi_count > 0 ?
        (total / coi_count.to_f).round : 100
    end
  end

  def count_weaknesses(c_r)
    weaknesses_count = {}
    weaknesses = @controller.eql?('conclusion') ? c_r.review.final_weaknesses.not_revoked :
      c_r.review.weaknesses.not_revoked

    weaknesses.each do |w|
      @risk_levels |= RISK_TYPES.sort { |r1, r2| r2[1] <=> r1[1] }.map { |r| r.first }

      weaknesses_count[w.risk_text] ||= 0

      if w.repeated? && @controller.eql?('follow_up')
        @repeated_count += 1
      else
        weaknesses_count[w.risk_text] += 1
      end
    end

    @weaknesses_count_text = get_weaknesses_count_text(weaknesses_count)
  end

  def get_weaknesses_count_text(weaknesses_count)
    if weaknesses_count.values.sum == 0
      t("#{@controller}_committee_report.synthesis_report.without_weaknesses")
    else
      @risk_levels.map do |risk|
        risk_text = t("risk_types.#{risk}")
        "#{risk_text}: #{weaknesses_count[risk_text] || 0}"
      end
    end
  end

  def get_process_controls_text
    @process_controls.sort do |pc1, pc2|
      pc1[1] <=> pc2[1]
    end.map { |pc| "#{pc[0]} (#{'%.2f' % pc[1]}%)" }
  end

  def get_nonconformities_count_text(c_r)
    c_r.review.nonconformities.not_revoked.count > 0 ?
      c_r.review.nonconformities.not_revoked.count.to_s :
      t("#{@controller}_committee_report.synthesis_report.without_nonconformities")
  end

  def get_oportunities_count_text(c_r)
    c_r.review.oportunities.not_revoked.count > 0 ?
      c_r.review.final_oportunities.not_revoked.count.to_s :
      t("#{@controller}_committee_report.synthesis_report.without_oportunities")
  end

  def set_column_data(c_r)
    process_control_text = get_process_controls_text
    if @sqm
      nonconformities_count_text = get_nonconformities_count_text(c_r)
    else
      oportunities_count_text = get_oportunities_count_text(c_r)
    end
    @review_scores << c_r.review.score
    @column_data << [
      c_r.review.business_unit.name,
      c_r.review.to_s,
      c_r.review.reload,
      process_control_text,
      @risk_levels.blank? ?
        t('follow_up_committee_report.synthesis_report.without_weaknesses') :
        @weaknesses_count_text,
      @sqm ? nonconformities_count_text : oportunities_count_text
    ]
  end

  def sort_column_data
    @column_data.sort! do |cd_1, cd_2|
      cd_1[2].score <=> cd_2[2].score
    end

    @column_data.each do |data|
      data[2] = data[2].score_text
    end
  end

  def set_audits_by_business_unit_data(period, but)
    @audits_by_business_unit[period] ||= []
    @audits_by_business_unit[period] << {
      :name => but.name,
      :external => but.external,
      :columns => @columns,
      :column_data => @column_data,
      :review_scores => @review_scores,
      :repeated_count => @repeated_count
    }
  end

  def create_synthesis_report
    self.synthesis_report

    pdf = init_pdf(params[:report_title], params[:report_subtitle])
    add_pdf_description(pdf, 'follow_up', @from_date, @to_date)

    @periods.each do |period|
      add_period_title(pdf, period, :justify)
      add_average_score(period, pdf) if !@selected_business_unit

      @audits_by_business_unit[period].each do |data|
        prepare_columns(pdf, data[:columns])
        add_pdf_titles(pdf, data[:external], data[:name])
        prepare_rows(data[:column_data])

        if @column_data.present?
          add_pdf_table(pdf)
          add_score_data(pdf, data[:review_scores], data[:name])
          add_repeated_text(pdf, data[:repeated_count]) if @controller.eql?('follow_up')
        else
          pdf.text t("#{@controller}_committee_report.synthesis_report.without_audits_in_the_period"),
            :style => :italic
        end
      end
    end

    add_pdf_filters(pdf, 'follow_up', @filters) if @filters.present?

    add_pdf_references(pdf)

    save_pdf(pdf, @controller, @from_date, @to_date, 'synthesis_report')
    redirect_to_pdf(@controller, @from_date, @to_date, 'synthesis_report')
  end

  def add_pdf_table(pdf)
    pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
      table_options = pdf.default_table_options(@column_widths)
      pdf.table(@column_data.insert(0, @column_headers), table_options) do
        row(0).style(
          :background_color => 'cccccc',
          :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
        )
      end
    end
  end

  def prepare_rows(column_data)
    @column_data = []

    column_data.each do |row|
      new_row = []

      row.each do |column|
        new_row << (column.kind_of?(Array) ?
          column.map {|l| " • #{l}"}.join("\n") :
          column)
      end

      @column_data << new_row
    end
  end

  def add_pdf_references(pdf)
    pdf.move_down PDF_FONT_SIZE

    references = @sqm ? t("#{@controller}_committee_report.synthesis_report.sqm_references",
      :risk_types => @risk_levels.to_sentence) :
      t("#{@controller}_committee_report.synthesis_report.references", :risk_types => @risk_levels.to_sentence)

    pdf.text references, :font_size => (PDF_FONT_SIZE * 0.75).round,
      :align => :justify
  end

  def add_repeated_text(pdf, repeated_count)
    pdf.text(t('follow_up_committee_report.synthesis_report.repeated_count',
      :count => repeated_count), :font_size => PDF_FONT_SIZE) if repeated_count > 0
  end

  def add_score_data(pdf, scores, audit_type_name)
    unless scores.blank?
      title = t("#{@controller}_committee_report.synthesis_report.generic_score_average",
        :count => scores.size, :audit_type => audit_type_name)
      text = "<b>#{title}</b>: <i>#{(scores.sum.to_f / scores.size).round}%</i>"
    else
      text = t('conclusion_committee_report.synthesis_report.without_audits_in_the_period')
    end

    pdf.move_down PDF_FONT_SIZE

    pdf.text text, :font_size => PDF_FONT_SIZE, :inline_format => true
  end

  def add_average_score(period, pdf)
    unless @audits_by_business_unit[period].blank?
      count = 0

      internal_audits_by_business_unit = @audits_by_business_unit[period].reject do |but|
        but[:external]
      end

      total = internal_audits_by_business_unit.inject(0) do |sum, data|
        scores = data[:review_scores]

        if scores.blank?
          sum
        else
          count += 1
          sum + (scores.sum.to_f / scores.size).round
        end
      end

      average_score = count > 0 ? (total.to_f / count).round : 100
    end

    add_pdf_score(pdf, period, average_score)
  end

  def add_pdf_score(pdf, period, average_score)
    pdf.move_down PDF_FONT_SIZE

    pdf.add_title(
      t('follow_up_committee_report.synthesis_report.organization_score',
        :score => average_score || 100), (PDF_FONT_SIZE * 1.5).round)

    pdf.move_down((PDF_FONT_SIZE * 0.75).round)

    pdf.text(
      t('follow_up_committee_report.synthesis_report.organization_score_note',
        :audit_types =>
          @audits_by_business_unit[period].map { |data|
            data[:name]
          }.to_sentence),
      :font_size => (PDF_FONT_SIZE * 0.75).round)
  end

  def prepare_columns(pdf, columns)
    @column_headers, @column_widths = [], []

    @column_order.each do |col_name|
      @column_headers << "<b>#{columns[col_name].first}</b>"
      @column_widths << pdf.percent_width(columns[col_name].last)
    end
  end

  def add_pdf_titles(pdf, external, but_name)
    if external && !@internal_title_showed
      title = t "#{@controller}_committee_report.synthesis_report.internal_audit_weaknesses"
      @internal_title_showed = true
    elsif external && !@external_title_showed
      title = t "#{@controller}_committee_report.synthesis_report.external_audit_weaknesses"
      @external_title_showed = true
    end

    if title
      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title title, (PDF_FONT_SIZE * 1.25).round, :center
    end

    pdf.add_subtitle but_name, PDF_FONT_SIZE, PDF_FONT_SIZE
  end
end
