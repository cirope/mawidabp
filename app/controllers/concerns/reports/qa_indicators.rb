module Reports::QAIndicators
  include Reports::Pdf

  def qa_indicators
    init_qa_vars
    calculate_ancient_weaknesses_data

    @periods.each do |period|
      init_qa_period_vars(period)
      calculate_indexes(period)
      add_indicators(period)
    end
  end

  def init_qa_vars
    @title = t('follow_up_committee_report.qa_indicators_title')
    @from_date, @to_date = *make_date_range(params[:qa_indicators])
    @periods = periods_for_interval
    @columns = [
      ['indicator', t('follow_up_committee_report.qa_indicators.indicator')],
      ['value', t('follow_up_committee_report.qa_indicators.value')]
    ]
    @conclusion_reviews = ConclusionFinalReview.list_all_by_date(
      @from_date, @to_date
    )
    @indicators = {}
  end

  def init_qa_period_vars(period)
    @indexes = {}
    @cfrs = @conclusion_reviews.for_period(period).list_all_by_date(@from_date, @to_date)
    @row_order = [
      ['%.1f%%', :highest_solution_rate],
      ['%.1f%%', :oportunities_solution_rate],
      ['%.1f%%', :digitalized],
      ['%d%%', :score_average],
      ['%.1f%%', :production_level]
    ]
  end

  def calculate_ancient_weaknesses_data
    @medium_risk_days = @medium_risk_total = 0
    @highest_risk_days = @highest_risk_total = 0

    count_qa_weaknesses
    add_ancient_risk_labels
  end

  def count_qa_weaknesses
    # Tomo todos los informes de definitivos sin tener en cuenta el filtro de fechas
    ConclusionFinalReview.list.each do |cfr|
      medium_risk_weaknesses = cfr.review.weaknesses.with_medium_risk.being_implemented
      highest_risk_weaknesses = cfr.review.weaknesses.with_highest_risk.being_implemented

      medium_risk_weaknesses.each do |w|
        @medium_risk_days += (Date.today - w.origination_date).abs.round
        @medium_risk_total += 1
      end

      highest_risk_weaknesses.each do |w|
        @highest_risk_days += (Date.today - w.origination_date).abs.round
        @highest_risk_total += 1
      end
    end
  end

  def add_ancient_risk_labels
    ancient_medium_risk_weaknesses = @medium_risk_total > 0 ?
      (@medium_risk_days / @medium_risk_total).round : nil

    ancient_highest_risk_weaknesses = @highest_risk_total > 0 ?
      (@highest_risk_days / @highest_risk_total).round : nil

    @ancient_medium_risk_label =
      "#{t('follow_up_committee_report.qa_indicators.indicators.ancient_medium_risk_weaknesses')}:
       #{t('label.day', :count => ancient_medium_risk_weaknesses)}" if ancient_medium_risk_weaknesses

    @ancient_highest_risk_label =
      "#{t('follow_up_committee_report.qa_indicators.indicators.ancient_highest_risk_weaknesses')}:
       #{t('label.day', :count => ancient_highest_risk_weaknesses)}" if ancient_highest_risk_weaknesses
  end

  def calculate_highest_weaknesses_solution_rate
    pending_highest_risk = @cfrs.inject(0.0) do |ct, cr|
      ct + cr.review.weaknesses.with_highest_risk.where(
        :state => Weakness::STATUS.except(Weakness::EXCLUDE_FROM_REPORTS_STATUS).values
      ).count
    end

    resolved_highest_risk = @cfrs.inject(0.0) do |ct, cr|
      ct + cr.review.weaknesses.with_highest_risk.where(
        :state => Weakness::STATUS.except(Weakness::EXCLUDE_FROM_REPORTS_STATUS).values - Weakness::PENDING_STATUS
      ).count
    end

    @indexes[:highest_solution_rate] = pending_highest_risk > 0 ?
      (resolved_highest_risk / pending_highest_risk.to_f) * 100 : nil
  end

  def calculate_oportunities_solution_rate
    pending_oportunities = @cfrs.inject(0.0) do |ct, cr|
      ct + cr.review.oportunities.where(
        :state => Oportunity::STATUS.except(Oportunity::EXCLUDE_FROM_REPORTS_STATUS).values
      ).count
    end

    resolved_oportunities = @cfrs.inject(0.0) do |ct, cr|
      ct + cr.review.oportunities.where(
        :state => Oportunity::STATUS.except(Oportunity::EXCLUDE_FROM_REPORTS_STATUS).values - Oportunity::PENDING_STATUS
      ).count
    end

    @indexes[:oportunities_solution_rate] = pending_oportunities > 0 ?
      (resolved_oportunities / pending_oportunities.to_f) * 100 : nil
  end

  def calcultate_medium_weaknesses_solution_rate
    pending_medium_risk = @cfrs.inject(0.0) do |ct, cr|
      ct + cr.review.weaknesses.where(
        'state IN(:state) AND (highest_risk - 1) = risk',
        :state => Weakness::STATUS.except(Weakness::EXCLUDE_FROM_REPORTS_STATUS).values
      ).count
    end

    resolved_medium_risk = @cfrs.inject(0.0) do |ct, cr|
      ct + cr.review.weaknesses.where(
        'state IN(:state) AND (highest_risk - 1) = risk',
        :state => Weakness::STATUS.except(Weakness::EXCLUDE_FROM_REPORTS_STATUS).values - Weakness::PENDING_STATUS
      ).count
    end

    @indexes[:medium_solution_rate] = pending_medium_risk > 0 ?
      (resolved_medium_risk / pending_medium_risk.to_f) * 100 : nil
  end

  def calculate_production_level(period)
    reviews_count = period.plans.to_a.sum do |p|
      final_review_count = p.plan_items.joins(
        :review => :conclusion_final_review
      ).with_business_unit.between(@from_date, @to_date).count
      last_day_count = p.plan_items.references(:conclusion_final_review).includes(
        :review => :conclusion_final_review,
      ).with_business_unit.between(@from_date, @to_date).where(
        "#{ConclusionFinalReview.table_name}.review_id" => nil, end: @to_date
      ).count

      final_review_count + last_day_count
    end

    plan_items_count = period.plans.to_a.sum do |p|
      p.plan_items.with_business_unit.between(@from_date, @to_date).count
    end

    @indexes[:production_level] = plan_items_count > 0 ?
      (reviews_count / plan_items_count.to_f) * 100 : nil
  end

  def calculate_score_average
    internal_cfrs = @cfrs.internal_audit.includes(:review)
    scores = []

    BusinessUnitType.list.each do |but|
      score = 0
      total = 0
      internal_cfrs.each do |cfrs|
        if cfrs.review.business_unit.business_unit_type_id == but.id
          score += cfrs.review.score.to_f
          total += 1
        end
      end

      scores << (score / total) unless total == 0
    end

    scores.size == 0 ? @indexes[:score_average] = 0 :
      @indexes[:score_average] = (scores.inject(0) { |i, score | i + score } / scores.size).round
  end

  def calculate_work_papers_digitalization
    wps = WorkPaper.list.includes(:owner, :file_model).where(
      'created_at BETWEEN :start AND :end',
      start: @from_date, end: @to_date
    ).select { |wp| wp.owner.try(:is_in_a_final_review?) }

    wps_with_files = wps.select { |wp| wp.file_model.try(:file?) }

    @indexes[:digitalized] = wps.size > 0 ?
      (wps_with_files.size.to_f / wps.size) * 100 : nil
  end

  def calculate_indexes(period)
    calculate_highest_weaknesses_solution_rate
    calculate_oportunities_solution_rate
    calcultate_medium_weaknesses_solution_rate
    calculate_production_level(period)
    calculate_score_average
    calculate_work_papers_digitalization
  end

  def add_indicators(period)
    @indicators[period] ||= []
    @indicators[period] << {
      :column_data => @row_order.map do |mask, i|
        {
          'indicator' => t("follow_up_committee_report.qa_indicators.indicators.#{i}"),
          'value' => (mask % @indexes[i] if @indexes[i])
        }
      end
    }
  end

  def create_qa_indicators
    self.qa_indicators

    pdf = init_pdf(params[:report_title], params[:report_subtitle])
    add_pdf_description(pdf, 'follow_up', @from_date, @to_date)

    @periods.each do |period|
      add_period_title(pdf, period)
      prepare_indicators_data(pdf, period)
      add_ancient_indicators(pdf)
    end

    save_pdf(pdf, 'follow_up', @from_date, @to_date, 'qa_indicators')
    redirect_to_pdf('follow_up', @from_date, @to_date, 'qa_indicators')
  end

  def prepare_indicators_data(pdf, period)
    @indicators[period].each do |data|
      prepare_qa_columns(pdf)
      prepare_qa_rows(data)
      add_qa_indicators_pdf_table(pdf)
    end
  end

  def prepare_qa_columns(pdf)
    @column_data, @column_headers, @column_widths = [], [], []

    @columns.each do |col_name|
      @column_headers << "<b>#{col_name.last}</b>"
      @column_widths << pdf.percent_width(50)
    end
  end

  def prepare_qa_rows(data)
    data[:column_data].each do |row|
      new_row = []

      row.each do |column_name, column_content|
        new_row << (column_content.present? ? column_content :
          (t'follow_up_committee_report.qa_indicators.without_data'))
      end

      @column_data << new_row
    end
  end

  def add_qa_indicators_pdf_table(pdf)
    unless @column_data.blank?
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(@column_widths)

        pdf.table(@column_data.insert(0, @column_headers), table_options) do
        row(0).style(
          :background_color => 'cccccc',
          :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
        )
        end
      end
    else
      pdf.text(
        t('follow_up_committee_report.qa_indicators.without_audits_in_the_period'),
        :style => :italic)
    end
  end

  def add_ancient_indicators(pdf)
    pdf.move_down PDF_FONT_SIZE
    pdf.text @ancient_medium_risk_label if @ancient_medium_risk_label
    pdf.text @ancient_highest_risk_label if @ancient_highest_risk_label
  end
end
