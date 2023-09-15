module Reports::NbcCycleRating
  include Reports::Pdf

  def nbc_cycle_rating
    @form = NbcCycleRatingForm.new new_cycle_rating_report
  end

  def create_nbc_cycle_rating
    @form = NbcCycleRatingForm.new new_cycle_rating_report

    if @form.validate(params[:nbc_cycle_rating])
      @controller              = 'conclusion'
      period                   = @form.period
      previous_period          = @form.previous_period
      business_unit_type       = @form.business_unit_type
      organization             = Current.organization
      pdf                      = Prawn::Document.create_generic_pdf :portrait, margins: [30, 20, 20, 25]
      business_units           = BusinessUnit.where(business_unit_types: business_unit_type)

      text_titles              = [
        business_unit_type.name,
        I18n.t('conclusion_committee_report.nbc_cycle_rating.front_page.second_title')
      ]

      put_nbc_cover_on               pdf, organization, text_titles, @form
      put_nbc_executive_summary      pdf, organization, @form
      put_nbc_introduction_and_scope pdf, @form
      put_nbc_scores_on              pdf, business_units, period
      put_nbc_comparison_table       pdf, business_units, period, previous_period
      put_nbc_detailed_scores_on     pdf, business_units, period, previous_period

      save_pdf pdf, @controller, period.start, period.end, 'nbc_cycle_rating'
      redirect_to_pdf @controller, period.start, period.end, 'nbc_cycle_rating'
    else
      render action: :nbc_cycle_rating
    end
  end

  private

    def new_cycle_rating_report
      OpenStruct.new(
        period_id: '',
        date: Date.today,
        cc: '',
        name: '',
        objective: '',
        conclusion: '',
        introduction_and_scope: ''
      )
    end

    def get_scores business_units, period
      weaknesses = Weakness
        .joins(:business_unit_type)
        .joins(control_objective_item: { review: :period })
        .where(
          business_units: business_units,
          reviews: { periods: period },
          final: true
        )

      weaknesses.group_by do |w|
        date = w.review.conclusion_final_review.issue_date

        [w.risk_weight, w.state_weight, w.age_weight(date: date)]
      end
    end

    def put_nbc_scores_on pdf, business_units, period
      pdf.move_down PDF_FONT_SIZE * 3

      pdf.text I18n.t('conclusion_review.nbc.scores.cycle'), inline_format: true
      pdf.move_down PDF_FONT_SIZE
      pdf.text I18n.t('conclusion_review.nbc.scores.description'), align: :justify

      data       = [nbc_header_scores]
      sum_weight = 0
      total_sum  = 0
      scores     = get_scores business_units, period

      scores.each do |row, weaknesses|
        risk_text = weaknesses.first.risk_text

        row.unshift weaknesses.size

        weight      = row.inject &:*
        sum_weight += weight
        total_sum  += weaknesses.count

        data << [risk_text] + row + [weight]
      end

      business_unit_weight = sum_weight.to_f / business_units.count
      rating               = calculate_qualification business_unit_weight

      data << [
        I18n.t('conclusion_committee_report.nbc_cycle_rating.nbc_scores.footer.totals'),
        total_sum,
        { content: '', colspan: 3 },
        sum_weight
      ]
      data << [
        { content: I18n.t('conclusion_committee_report.nbc_cycle_rating.nbc_scores.footer.business_units'), colspan: 5 },
        business_units.count
      ]
      data << [
        { content: I18n.t('conclusion_committee_report.nbc_cycle_rating.nbc_scores.footer.weighter'), colspan: 5 },
        business_unit_weight
      ]
      data << [
        { content: I18n.t('conclusion_committee_report.nbc_cycle_rating.nbc_scores.footer.cycle_rating'), colspan: 5 },
        rating
      ]

      pdf.move_down PDF_FONT_SIZE

      pdf.font_size (PDF_FONT_SIZE * 0.75).round do
        pdf.table data do |t|
          t.column_widths = pdf.bounds.width / 6
          t.cells.align = :center
          t.cells.row(0).style(
            background_color: '6e9fcf',
            align: :center,
            font_style: :bold
          )
          t.cells.row(-1).style(
            background_color: '6e9fcf',
            align: :center,
            font_style: :bold
          )
        end
      end
    end

    def nbc_header_scores
      [
        I18n.t('conclusion_review.nbc.scores.risk'),
        I18n.t('conclusion_review.nbc.scores.amount_weaknesses'),
        I18n.t('conclusion_review.nbc.scores.level_risk'),
        I18n.t('conclusion_review.nbc.scores.status'),
        I18n.t('conclusion_review.nbc.scores.age_parameter'),
        I18n.t('conclusion_review.nbc.scores.weighing')
      ]
    end

    def put_nbc_comparison_table pdf, business_units, period, previous_period
      pdf.move_down PDF_FONT_SIZE

      data              = [nbc_comparison_table_headers]
      current_scores    = get_scores business_units, period
      current_weighter  = current_scores.keys.reduce(0) { |sum, array| sum + array.reduce(:*) }
      current_rating    = calculate_qualification current_weighter
      previous_scores   = get_scores business_units, previous_period
      previous_weighter = current_scores.keys.reduce(0) { |sum, array| sum + array.reduce(:*) }
      previous_rating   = calculate_qualification current_weighter

      data << [period.name, current_weighter, current_rating]
      data << [previous_period.name, previous_weighter, previous_rating]

      pdf.font_size (PDF_FONT_SIZE * 0.75).round do
        pdf.table data do |t|
          t.column_widths = pdf.bounds.width / 3
          t.cells.align = :center
          t.cells.row(0).style(
            background_color: '6e9fcf',
            align: :center,
            font_style: :bold
          )
        end

        pdf.move_down PDF_FONT_SIZE
        pdf.text I18n.t('conclusion_review.nbc.scores.legend_score'), align: :justify
      end
    end

    def nbc_comparison_table_headers
      [
        I18n.t('conclusion_committee_report.nbc_cycle_rating.nbc_comparison_table.headers.comparison'),
        I18n.t('conclusion_committee_report.nbc_cycle_rating.nbc_comparison_table.headers.weighting'),
        I18n.t('conclusion_committee_report.nbc_cycle_rating.nbc_comparison_table.headers.rating')
      ]
    end

    def calculate_weighter business_unit, period
      weaknesses = Weakness
        .joins(:business_unit)
        .joins(control_objective_item: { review: :period })
        .where(
          business_units: business_unit,
          reviews: { periods: period },
          final: true
        )

      bu_weighter = []

      weaknesses.each do |w|
        date     = w.review.conclusion_final_review.issue_date
        weighter = w.risk_weight * w.state_weight * w.age_weight(date: date)

        bu_weighter << weighter
      end

      bu_weighter.sum
    end

    def put_nbc_detailed_scores_on pdf, business_units, period, previous_period
      pdf.move_down PDF_FONT_SIZE

      pdf.text I18n.t(
        'conclusion_committee_report.nbc_cycle_rating.nbc_detailed_scores.introduction',
        period_name: period.name, previous_period_name: previous_period.name
      ), align: :justify

      data = [header_score_per_business_unit]

      business_units.each do |business_unit|
        current_weighter  = calculate_weighter business_unit, period
        current_rating    = calculate_qualification current_weighter
        previous_weighter = calculate_weighter business_unit, previous_period
        previous_rating   = calculate_qualification previous_weighter

        data << [business_unit.name, current_weighter, current_rating, previous_weighter, previous_rating]
      end

      pdf.move_down PDF_FONT_SIZE

      pdf.font_size (PDF_FONT_SIZE * 0.75).round do
        pdf.table data do |t|
          t.column_widths = pdf.bounds.width / 5
          t.cells.align = :center
          t.cells.row(0).style(
            background_color: '6e9fcf',
            align: :center,
            font_style: :bold
          )
        end
      end
    end

    def header_score_per_business_unit
      [
        I18n.t('conclusion_committee_report.nbc_cycle_rating.nbc_detailed_scores.headers.business_unit'),
        I18n.t('conclusion_committee_report.nbc_cycle_rating.nbc_detailed_scores.headers.current_weighter'),
        I18n.t('conclusion_committee_report.nbc_cycle_rating.nbc_detailed_scores.headers.current_rating'),
        I18n.t('conclusion_committee_report.nbc_cycle_rating.nbc_detailed_scores.headers.previous_weighter'),
        I18n.t('conclusion_committee_report.nbc_cycle_rating.nbc_detailed_scores.headers.previous_rating')
      ]
    end
end
