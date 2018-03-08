module Reports::ReviewScoresReport
  include Reports::Pdf
  include Parameters::Risk

  def review_scores_report
    init_review_scores_vars

    if params[:review_scores_report]
      review_scores_business_unit_type_reviews if params[:review_scores_report][:business_unit_type].present?
      review_scores_business_unit_reviews if params[:review_scores_report][:business_unit].present?
    end

    set_review_scores_data
  end

  def create_review_scores_report
    review_scores_report

    pdf = init_pdf params[:report_title], params[:report_subtitle]

    add_pdf_description pdf, @controller, @from_date, @to_date

    add_reviews_scores pdf

    add_pdf_filters pdf, @controller, @filters if @filters.present?

    save_pdf pdf, @controller, @from_date, @to_date, 'review_scores_report'
    redirect_to_pdf @controller, @from_date, @to_date, 'review_scores_report'
  end

  private

    def init_review_scores_vars
      @controller = params[:controller_name]
      @final = @controller == 'conclusion'
      @title = t("#{@controller}_committee_report.review_scores_report_title")
      @from_date, @to_date = *make_date_range(params[:review_scores_report])
      @filters = []
      @business_unit_scores = {}
      @business_unit_data = []
      @conclusion_reviews = ConclusionFinalReview.
        includes(:review).
        list_all_by_date @from_date, @to_date
    end

    def review_scores_business_unit_type_reviews
      @selected_business_unit = BusinessUnitType.find params[:review_scores_report][:business_unit_type]
      @conclusion_reviews = @conclusion_reviews.by_business_unit_type @selected_business_unit.id
      @filters << "<b>#{BusinessUnitType.model_name.human}</b> = \"#{@selected_business_unit.name.strip}\""
    end

    def review_scores_business_unit_reviews
      business_units = params[:review_scores_report][:business_unit].split(
        SPLIT_AND_TERMS_REGEXP
      ).uniq.map(&:strip)

      if business_units.present?
        @conclusion_reviews = @conclusion_reviews.by_business_unit_names *business_units
        @filters << "<b>#{BusinessUnit.model_name.human}</b> = \"#{params[:review_scores_report][:business_unit].strip}\""
      end
    end

    def set_review_scores_data
      @conclusion_reviews.each do |cr|
        review = cr.review

        @business_unit_scores[review.business_unit.id] =
          get_review_scores_for(review)

        put_business_unit_scores_for review
      end

      @business_unit_data = review_scores_data
    end

    def get_review_scores_for review
      scores = @business_unit_scores[review.business_unit.id] || []

      review.control_objective_items.not_excluded_from_score.each do |coi|
        scores << {
          type:      :review,
          value:     coi.effectiveness.to_f,
          relevance: coi.relevance
        }
      end

      scores
    end

    def put_business_unit_scores_for review
      review.business_unit_scores.each do |bus|
        coi = bus.control_objective_item

        unless coi.exclude_from_score
          bu_scores = @business_unit_scores[bus.business_unit_id] || []

          bu_scores << {
            type:      :business_unit,
            value:     bus.effectiveness.to_f,
            relevance: coi.relevance
          }

          @business_unit_scores[bus.business_unit_id] = bu_scores
        end
      end
    end

    def add_reviews_scores pdf
      pdf.move_down PDF_FONT_SIZE
      pdf.add_title BusinessUnit.model_name.human(count: 0),
        (PDF_FONT_SIZE * 1.25).round
      pdf.move_down PDF_FONT_SIZE

      if @business_unit_data.present?
        add_review_scores_report_pdf_table pdf
      else
        pdf.text t("#{@controller}_committee_report.review_scores_report.empty"),
          style: :italic
      end
    end

    def review_scores_columns
      {
        BusinessUnit.model_name.human => 40,
        I18n.t("#{@controller}_committee_report.review_scores_report.review_score") => 20,
        I18n.t("#{@controller}_committee_report.review_scores_report.business_unit_score") => 20,
        I18n.t("#{@controller}_committee_report.review_scores_report.total_score") => 20
      }
    end

    def review_scores_column_widths pdf
      review_scores_columns.map { |name, width| pdf.percent_width width }
    end

    def review_scores_column_headers pdf
      review_scores_columns.map { |name, width| "<b>#{name}</b>" }
    end

    def review_scores_data
      @business_unit_scores.map do |bu_id, scores|
        bu         = BusinessUnit.list.find bu_id
        r_scores   = get_scores_by_type scores, :review
        bu_scores  = get_scores_by_type scores, :business_unit
        all_scores = r_scores + bu_scores

        score_avg    = review_score_avg r_scores
        bu_score_avg = review_score_avg bu_scores
        all_avg      = review_score_avg all_scores

        [bu.name, score_avg, bu_score_avg, all_avg]
      end
    end

    def add_review_scores_report_pdf_table pdf
      pdf.font_size (PDF_FONT_SIZE * 0.75).round do
        table_options = pdf.default_table_options(review_scores_column_widths(pdf))
        pdf.table(@business_unit_data.insert(0, review_scores_column_headers(pdf)), table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    def review_score_avg scores
      if scores.size > 0
        relevances = scores.map(&:last)

        '%.2f' % ((scores.map { |s| s.first * s.last }.sum.to_f) / relevances.sum)
      else
        '-'
      end
    end

    def get_scores_by_type scores, type
      scores.select { |s| s[:type] == type }.map do |s|
        [s[:value], s[:relevance]]
      end
    end
end
