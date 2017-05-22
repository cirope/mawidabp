module Reports::ReviewStatsReport
  include Reports::Pdf
  include Parameters::Risk

  def review_stats_report
    init_review_stats_vars

    if params[:review_stats_report]
      review_stats_business_unit_type_reviews if params[:review_stats_report][:business_unit_type].present?
      review_stats_business_unit_reviews if params[:review_stats_report][:business_unit].present?
    end

    set_reviews_by_score_data
  end

  def create_review_stats_report
    review_stats_report

    pdf = init_pdf params[:report_title], params[:report_subtitle]

    add_pdf_description pdf, @controller, @from_date, @to_date

    add_review_stats pdf

    add_pdf_filters pdf, @controller, @filters if @filters.present?

    save_pdf pdf, @controller, @from_date, @to_date, 'review_stats_report'
    redirect_to_pdf @controller, @from_date, @to_date, 'review_stats_report'
  end

  private

    def init_review_stats_vars
      @controller = params[:controller_name]
      @final = @controller == 'conclusion'
      @title = t("#{@controller}_committee_report.review_stats_report_title")
      @from_date, @to_date = *make_date_range(params[:review_stats_report])
      @filters = []
      @reviews_by_score = {}
      @conclusion_reviews = ConclusionFinalReview.
        includes(:review).
        list_all_by_date @from_date, @to_date
    end

    def review_stats_business_unit_type_reviews
      @selected_business_unit = BusinessUnitType.find params[:review_stats_report][:business_unit_type]
      @conclusion_reviews = @conclusion_reviews.by_business_unit_type @selected_business_unit.id
      @filters << "<b>#{BusinessUnitType.model_name.human}</b> = \"#{@selected_business_unit.name.strip}\""
    end

    def review_stats_business_unit_reviews
      business_units = params[:review_stats_report][:business_unit].split(
        SPLIT_AND_TERMS_REGEXP
      ).uniq.map(&:strip)

      if business_units.present?
        @conclusion_reviews = @conclusion_reviews.by_business_unit_names *business_units
        @filters << "<b>#{BusinessUnit.model_name.human}</b> = \"#{params[:review_stats_report][:business_unit].strip}\""
      end
    end

    def set_reviews_by_score_data
      scores = Review.scores

      scores.keys.each { |score| @reviews_by_score[score] = [] }

      @conclusion_reviews.each do |cr|
        score = scores.detect { |score, value| cr.review.score.to_i >= value }

        @reviews_by_score[score.first] << cr.review.score.to_i
      end
    end

    def add_review_stats pdf
      count_label = I18n.t("#{@controller}_committee_report.review_stats_report.review_count")

      pdf.move_down PDF_FONT_SIZE

      pdf.add_title Review.model_name.human(count: 0), (PDF_FONT_SIZE * 1.25).round

      pdf.move_down PDF_FONT_SIZE

      add_review_stats_report_pdf_table pdf

      pdf.move_down PDF_FONT_SIZE

      pdf.text "<b>#{count_label}</b>: #{review_stats_score_count}", inline_format: true
    end

    def review_stats_columns
      {
        'score' => [Review.human_attribute_name('score'), 50],
        'ratio' => [I18n.t("#{@controller}_committee_report.review_stats_report.ratio"), 50]
      }
    end

    def review_stats_column_widths pdf
      review_stats_columns.map { |name, header| pdf.percent_width(header.last) }
    end

    def review_stats_column_headers pdf
      review_stats_columns.map { |name, header| "<b>#{header.first}</b>" }
    end

    def review_stats_score_count
      @reviews_by_score.values.map(&:size).sum
    end

    def review_stats_column_data
      Review.scores.map do |score, value|
        scores = @reviews_by_score[score]
        ratio  = if scores.size > 0
          '%.2f%' % (scores.size.to_f / review_stats_score_count * 100)
        else
          '0.00%'
        end

        [I18n.t("score_types.#{score}"), ratio]
      end
    end

    def add_review_stats_report_pdf_table(pdf)
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(review_stats_column_widths(pdf))
        pdf.table(review_stats_column_data.insert(0, review_stats_column_headers(pdf)), table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end
end
