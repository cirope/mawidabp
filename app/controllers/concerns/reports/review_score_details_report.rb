module Reports::ReviewScoreDetailsReport
  include Reports::PDF
  include Parameters::Risk

  def review_score_details_report
    init_review_score_details_vars

    respond_to do |format|
      format.html
      format.csv do
        render csv: review_score_details_csv, filename: @title.downcase
      end
    end
  end

  def create_review_score_details_report
    init_review_score_details_vars

    pdf = init_pdf params[:report_title], params[:report_subtitle]

    add_pdf_description pdf, @controller, @from_date, @to_date

    add_review_score_detail_briefs pdf
    add_review_score_details pdf

    add_pdf_filters pdf, @controller, @filters if @filters.present?

    save_pdf pdf, @controller, @from_date, @to_date, 'review_score_details_report'
    redirect_to_pdf @controller, @from_date, @to_date, 'review_score_details_report'
  end

  private

    def review_score_details_csv
      options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

      csv_str = ::CSV.generate(options) do |csv|
        csv << review_score_details_csv_headers

        review_score_details_csv_rows.each { |row| csv << row }
      end

      "\uFEFF#{csv_str}"
    end

    def init_review_score_details_vars
      @controller = params[:controller_name]
      @title = t("#{@controller}_committee_report.review_score_details_report_title")
      @from_date, @to_date = *make_date_range(params[:review_score_details_report])
      @filters = []
      @conclusion_reviews = ConclusionFinalReview.
        includes(:review).
        references(:review).
        list_all_by_date @from_date, @to_date

      if params[:review_score_details_report]
        if params[:review_score_details_report][:business_unit].present?
          review_score_details_business_unit_reviews
        end

        review_score_details_business_unit_type_reviews
        review_score_details_reviews_by_conclusion
        review_score_details_reviews_by_scope
      end

      set_scores_by_scope
      set_scores_by_evolution
    end

    def review_score_details_business_unit_type_reviews
      business_unit_types = Array(params[:review_score_details_report][:business_unit_type]).reject(&:blank?)

      if business_unit_types.any?
        selected_business_units = BusinessUnitType.list.where(id: business_unit_types)
        @conclusion_reviews = @conclusion_reviews.by_business_unit_type selected_business_units.ids
        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = \"#{selected_business_units.pluck('name').to_sentence}\""
      end
    end

    def review_score_details_business_unit_reviews
      business_units = params[:review_score_details_report][:business_unit].split(
        SPLIT_AND_TERMS_REGEXP
      ).uniq.map(&:strip)

      if business_units.present?
        @conclusion_reviews = @conclusion_reviews.by_business_unit_names *business_units
        @filters << "<b>#{BusinessUnit.model_name.human}</b> = \"#{params[:review_score_details_report][:business_unit].strip}\""
      end
    end

    def review_score_details_reviews_by_conclusion
      conclusions = Array(params[:review_score_details_report][:conclusion]).reject(&:blank?)

      if conclusions.any?
        @conclusion_reviews = @conclusion_reviews.where(conclusion: conclusions)
        @filters << "<b>#{ConclusionFinalReview.human_attribute_name 'conclusion'}</b> = \"#{conclusions.to_sentence}\""
      end
    end

    def review_score_details_reviews_by_scope
      scopes = Array(params[:review_score_details_report][:scope]).reject(&:blank?)

      if scopes.any?
        @conclusion_reviews = @conclusion_reviews.where(reviews: { scope: scopes })
        @filters << "<b>#{Review.human_attribute_name 'scope'}</b> = \"#{scopes.to_sentence}\""
      end
    end

    def set_scores_by_scope
      scope_column = "#{Review.quoted_table_name}.#{Review.qcn 'scope'}"
      scores_by_scope = @conclusion_reviews.group(scope_column).count
      total = scores_by_scope.values.sum

      @scores_by_scope = scores_by_scope.each_with_object({}) do |scope_count, result|
        result[scope_count.first] = [scope_count.last, (scope_count.last / total.to_f) * 100]
      end

      @scores_by_scope["<b>#{t ('label.total')}</b>"] = [total, 100]
    end

    def set_scores_by_evolution
      scores_by_evolution = @conclusion_reviews.group(:evolution).count
      total = scores_by_evolution.values.sum

      @scores_by_evolution = scores_by_evolution.each_with_object({}) do |evolution_count, result|
        result[evolution_count.first] = [evolution_count.last, (evolution_count.last / total.to_f) * 100]
      end

      @scores_by_evolution["<b>#{t ('label.total')}</b>"] = [total, 100]
    end

    def add_review_score_detail_briefs pdf
      pdf.move_down PDF_FONT_SIZE
      pdf.add_title t("#{@controller}_committee_report.review_score_details_report.brief"),
        (PDF_FONT_SIZE * 1.25).round
      pdf.move_down PDF_FONT_SIZE * 0.75

      if @conclusion_reviews.any?
        add_review_score_details_scope_pdf_table pdf
        pdf.move_down PDF_FONT_SIZE
        add_review_score_details_evolution_pdf_table pdf
      else
        pdf.text t("#{@controller}_committee_report.review_score_details_report.empty"),
          style: :italic
      end
    end

    def add_review_score_details pdf
      pdf.move_down PDF_FONT_SIZE
      pdf.add_title t("#{@controller}_committee_report.review_score_details_report.details"),
        (PDF_FONT_SIZE * 1.25).round
      pdf.move_down PDF_FONT_SIZE * 0.75

      if @conclusion_reviews.any?
        add_review_score_details_pdf_table pdf
      else
        pdf.text t("#{@controller}_committee_report.review_score_details_report.empty"),
          style: :italic
      end
    end

    def add_review_score_details_pdf_table pdf
      pdf.font_size (PDF_FONT_SIZE * 0.5).round do
        table_options = pdf.default_table_options review_score_details_column_widths(pdf)

        pdf.table(review_score_details_data(pdf), table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    def add_review_score_details_scope_pdf_table pdf
      pdf.font_size (PDF_FONT_SIZE * 0.75).round do
        table_options = pdf.default_table_options review_score_by_scope_column_widths(pdf)

        pdf.table(review_score_by_scope_data(pdf), table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    def review_score_by_scope_columns
      {
        Review.human_attribute_name('scope') => 60,
        t("#{@controller}_committee_report.review_score_details_report.count") => 20,
        t("#{@controller}_committee_report.review_score_details_report.share") => 20
      }
    end

    def review_score_by_scope_column_widths pdf
      review_score_by_scope_columns.map { |name, width| pdf.percent_width width }
    end

    def review_score_by_scope_column_headers pdf
      review_score_by_scope_columns.map { |name, width| "<b>#{name}</b>" }
    end

    def review_score_by_scope_data pdf
      data = @scores_by_scope.map do |scope, values|
        [scope, values.first, '%.1f%%' % values.last]
      end

      data.insert 0, review_score_by_scope_column_headers(pdf)
    end

    def add_review_score_details_evolution_pdf_table pdf
      pdf.font_size (PDF_FONT_SIZE * 0.75).round do
        table_options = pdf.default_table_options review_score_by_evolution_column_widths(pdf)

        pdf.table(review_score_by_evolution_data(pdf), table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    def review_score_by_evolution_columns
      {
        Review.human_attribute_name('evolution') => 60,
        t("#{@controller}_committee_report.review_score_details_report.count") => 20,
        t("#{@controller}_committee_report.review_score_details_report.share") => 20
      }
    end

    def review_score_by_evolution_column_widths pdf
      review_score_by_evolution_columns.map { |name, width| pdf.percent_width width }
    end

    def review_score_by_evolution_column_headers pdf
      review_score_by_evolution_columns.map { |name, width| "<b>#{name}</b>" }
    end

    def review_score_by_evolution_data pdf
      data = @scores_by_evolution.map do |evolution, values|
        [evolution, values.first, '%.1f%%' % values.last]
      end

      data.insert 0, review_score_by_evolution_column_headers(pdf)
    end

    def review_score_details_csv_headers
      [
        Review.model_name.human,
        PlanItem.human_attribute_name('project'),
        BusinessUnitType.model_name.human,
        Tag.model_name.human,
        Review.human_attribute_name('scope'),
        Review.human_attribute_name('risk_exposure'),
        ConclusionFinalReview.human_attribute_name('issue_date'),
        ConclusionFinalReview.human_attribute_name('conclusion'),
        ConclusionFinalReview.human_attribute_name('evolution'),
        BusinessUnit.model_name.human,
        Review.human_attribute_name('manual_score')
      ]
    end

    def review_score_details_columns
      {
        Review.model_name.human => 10,
        PlanItem.human_attribute_name('project') => 17,
        BusinessUnitType.model_name.human => 10,
        Tag.model_name.human => 8,
        Review.human_attribute_name('scope') => 10,
        Review.human_attribute_name('risk_exposure') => 8,
        ConclusionFinalReview.human_attribute_name('issue_date') => 7,
        ConclusionFinalReview.human_attribute_name('conclusion') => 10,
        ConclusionFinalReview.human_attribute_name('evolution') => 10,
        BusinessUnit.model_name.human => 10
      }
    end

    def review_score_details_column_widths pdf
      review_score_details_columns.map { |name, width| pdf.percent_width width }
    end

    def review_score_details_column_headers pdf
      review_score_details_columns.map { |name, width| "<b>#{name}</b>" }
    end

    def review_score_details_data pdf
      data = @conclusion_reviews.map do |conclusion_review|
        [
          conclusion_review.review.identification,
          conclusion_review.review.plan_item.project,
          conclusion_review.review.business_unit_type.to_s,
          conclusion_review.review.tags.map(&:to_s).to_sentence,
          conclusion_review.review.scope,
          conclusion_review.review.risk_exposure,
          l(conclusion_review.issue_date),
          conclusion_review.conclusion,
          conclusion_review.evolution,
          conclusion_review.review.business_unit.to_s
        ]
      end

      data.insert 0, review_score_details_column_headers(pdf)
    end

    def review_score_details_csv_rows
      @conclusion_reviews.map do |conclusion_review|
        [
          conclusion_review.review.identification,
          conclusion_review.review.plan_item.project,
          conclusion_review.review.business_unit_type.to_s,
          conclusion_review.review.tags.map(&:to_s).to_sentence,
          conclusion_review.review.scope,
          conclusion_review.review.risk_exposure,
          l(conclusion_review.issue_date),
          conclusion_review.conclusion,
          conclusion_review.evolution,
          conclusion_review.review.business_unit.to_s,
          conclusion_review.review.manual_score
        ]
      end
    end
end
