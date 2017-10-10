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
    set_reviews_by_tag_data
    set_weaknesses_by_score_data
  end

  def create_review_stats_report
    review_stats_report

    pdf = init_pdf params[:report_title], params[:report_subtitle]

    add_pdf_description pdf, @controller, @from_date, @to_date

    add_reviews_stats pdf
    add_reviews_by_tag_stats pdf if @reviews_by_tag.present?
    add_weakneesses_by_score pdf

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
      @reviews_by_tag = {}
      @weaknesses_by_score = {}
      @total_weaknesses_by_score = {}
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

    def set_reviews_by_tag_data
      Tag.list.for_reviews.each do |tag|
        @reviews_by_tag[tag] = @conclusion_reviews.
          joins(:review).
          merge(Review.tagged_with(tag)).
          count
      end
    end

    def set_weaknesses_by_score_data
      ::RISK_TYPES.reverse_each do |risk, r_value|
        ::PRIORITY_TYPES.reverse_each do |priority, p_value|
          add_total_weaknesses_by_score(
            risk:     risk,
            r_value:  r_value,
            priority: priority,
            p_value:  p_value
          )
        end
      end
    end

    def add_total_weaknesses_by_score risk:, r_value:, priority:, p_value:
      score_max = 100
      label     = [
        I18n.t("risk_types.#{risk}"),
        I18n.t("priority_types.#{priority}")
      ].join(' / ')

      @weaknesses_by_score[label] = {}

      Review.scores.each do |score, min|
        @weaknesses_by_score[label][score] = @conclusion_reviews.
          joins(review: @final ? :final_weaknesses : :weaknesses).
          merge(Review.with_score_between(min, score_max)).
          merge(Weakness.where(risk: r_value, priority: p_value)).
          count

        @total_weaknesses_by_score[score] ||= 0
        @total_weaknesses_by_score[score] += @weaknesses_by_score[label][score]

        score_max = min - 1
      end
    end

    def review_stats_count_label
      I18n.t "#{@controller}_committee_report.review_stats_report.review_count"
    end

    def add_reviews_stats pdf
      pdf.move_down PDF_FONT_SIZE
      pdf.add_title Review.model_name.human(count: 0), (PDF_FONT_SIZE * 1.25).round
      pdf.move_down PDF_FONT_SIZE
      add_review_stats_report_pdf_table pdf
      pdf.move_down PDF_FONT_SIZE

      pdf.text "<b>#{review_stats_count_label}</b>: #{review_stats_score_count}", inline_format: true
    end

    def add_reviews_by_tag_stats pdf
      title    = I18n.t("#{@controller}_committee_report.review_stats_report.reviews_by_tag.title")
      footnote = I18n.t("#{@controller}_committee_report.review_stats_report.reviews_by_tag.footnote")

      pdf.move_down PDF_FONT_SIZE
      pdf.add_title title, (PDF_FONT_SIZE * 1.25).round
      pdf.move_down PDF_FONT_SIZE

      add_reviews_by_tag_pdf_table pdf

      pdf.move_down PDF_FONT_SIZE
      pdf.text "<b>#{review_stats_count_label}</b>: #{reviews_by_tag_count} <sup>(*)</sup>", inline_format: true
      pdf.move_down PDF_FONT_SIZE

      pdf.text "<sup>(*)</sup> #{footnote}", font_size: (PDF_FONT_SIZE * 0.75).round, inline_format: true
    end

    def add_weakneesses_by_score pdf
      title = I18n.t("#{@controller}_committee_report.review_stats_report.weaknesses_by_score.title")

      pdf.move_down PDF_FONT_SIZE
      pdf.add_title title, (PDF_FONT_SIZE * 1.25).round
      pdf.move_down PDF_FONT_SIZE
      add_weaknesses_by_score_pdf_table pdf
    end

    def review_stats_columns
      {
        Review.human_attribute_name('score') => 80,
        I18n.t("#{@controller}_committee_report.review_stats_report.ratio") => 20
      }
    end

    def review_stats_column_widths pdf
      review_stats_columns.map { |name, width| pdf.percent_width width }
    end

    def review_stats_column_headers pdf
      review_stats_columns.map { |name, width| "<b>#{name}</b>" }
    end

    def review_stats_score_count
      @reviews_by_score.values.map(&:size).sum
    end

    def review_stats_data
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
        pdf.table(review_stats_data.insert(0, review_stats_column_headers(pdf)), table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    def reviews_by_tag_columns
      {
        Tag.model_name.human => 80,
        I18n.t("#{@controller}_committee_report.review_stats_report.ratio") => 20
      }
    end

    def reviews_by_tag_column_widths pdf
      reviews_by_tag_columns.map { |name, width| pdf.percent_width width }
    end

    def reviews_by_tag_column_headers pdf
      reviews_by_tag_columns.map { |name, width| "<b>#{name}</b>" }
    end

    def reviews_by_tag_count
      @reviews_by_tag.values.sum
    end

    def reviews_by_tag_data
      @reviews_by_tag.map do |tag, count|
        ratio = if count > 0
                  '%.2f%' % (count.to_f / reviews_by_tag_count * 100)
                else
                  '0.00%'
                end

        [tag.to_s, ratio]
      end
    end

    def add_reviews_by_tag_pdf_table(pdf)
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(reviews_by_tag_column_widths(pdf))
        pdf.table(reviews_by_tag_data.insert(0, reviews_by_tag_column_headers(pdf)), table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    def weaknesses_by_score_columns
      risk_priority = [
        Weakness.human_attribute_name('risk'),
        Weakness.human_attribute_name('priority')
      ].join(' / ')

      columns = { risk_priority => 25 }

      Review.scores.keys.each do |score|
        columns[I18n.t("score_types.#{score}")] = 25
      end

      columns
    end

    def weaknesses_by_score_column_widths pdf
      weaknesses_by_score_columns.map { |name, width| pdf.percent_width width }
    end

    def weaknesses_by_score_column_headers pdf
      weaknesses_by_score_columns.map { |name, width| "<b>#{name}</b>" }
    end

    def weaknesses_by_score_data
      totals_row = [
        I18n.t("#{@controller}_committee_report.review_stats_report.weaknesses_by_score.total")
      ]

      rows = @weaknesses_by_score.map do |label, weaknesses_by_score|
        row = [label]

        Review.scores.keys.each { |score| row << weaknesses_by_score[score] }

        row
      end

      Review.scores.keys.each do |score|
        totals_row << @total_weaknesses_by_score[score]
      end

      rows << totals_row
    end

    def add_weaknesses_by_score_pdf_table(pdf)
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(weaknesses_by_score_column_widths(pdf))
        pdf.table(weaknesses_by_score_data.insert(0, weaknesses_by_score_column_headers(pdf)), table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end
end
