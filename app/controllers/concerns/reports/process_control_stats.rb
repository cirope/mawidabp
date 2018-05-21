module Reports::ProcessControlStats
  include Reports::PDF
  include Reports::Period
  include Parameters::Risk

  def process_control_stats
    @controller = params[:controller_name]
    final = params[:final] == 'true'
    @title = t("#{@controller}_committee_report.process_control_stats_title")
    @from_date, @to_date = *make_date_range(params[:process_control_stats])
    @periods = periods_for_interval
    @risk_levels = []
    @filters = []
    @columns = [
      ['process_control', BestPractice.human_attribute_name('process_controls.name'), 60],
      ['effectiveness', t("#{@controller}_committee_report.process_control_stats.average_effectiveness"), 20],
      ['weaknesses_count', t('review.weaknesses_count'), 20]
    ]
    conclusion_reviews = ConclusionFinalReview.list_all_by_date(
      @from_date, @to_date
    )
    @best_practices = []
    @process_controls = []
    @process_control_data = {}
    @process_control_ids_data = {}
    @review_identifications = {}
    @reviews_score_data = {}
    reviews_score_data = {}
    weaknesses_conditions = {}

    if params[:process_control_stats]
      if params[:process_control_stats][:best_practice].present?
        @best_practices = params[:process_control_stats][:best_practice].split(
          SPLIT_AND_TERMS_REGEXP
        ).uniq.map(&:strip)

        if @best_practices.present?
          @filters << "<b>#{BestPractice.model_name.human}</b> = \"#{params[:process_control_stats][:best_practice].strip}\""

          conclusion_reviews = conclusion_reviews.by_best_practice_names *@best_practices
        end
      end

      if params[:process_control_stats][:process_control].present?
        @process_controls = params[:process_control_stats][:process_control].split(
          SPLIT_AND_TERMS_REGEXP
        ).uniq.map(&:strip)

        if @process_controls.present?
          @filters << "<b>#{ProcessControl.model_name.human}</b> = \"#{params[:process_control_stats][:process_control].strip}\""

          conclusion_reviews = conclusion_reviews.by_process_control_names *@process_controls
        end
      end

      if params[:process_control_stats][:business_unit_type].present?
        @selected_business_unit = BusinessUnitType.find(params[:process_control_stats][:business_unit_type])
        conclusion_reviews = conclusion_reviews.by_business_unit_type(@selected_business_unit.id)
        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = \"#{@selected_business_unit.name.strip}\""
      end

      if params[:process_control_stats][:business_unit].present?
        business_units = params[:process_control_stats][:business_unit].split(
          SPLIT_AND_TERMS_REGEXP
        ).uniq.map(&:strip)
        @business_unit_ids = business_units.present? && BusinessUnit.by_names(*business_units).pluck('id')

        unless business_units.empty?
          conclusion_reviews = conclusion_reviews.by_business_unit_names(*business_units)
          @filters << "<b>#{BusinessUnit.model_name.human}</b> = \"#{params[:process_control_stats][:business_unit].strip}\""
        end
      end

      if params[:process_control_stats][:finding_status].present?
        weaknesses_conditions[:state] = params[:process_control_stats][:finding_status]
        state_text = t "findings.state.#{Finding::STATUS.invert[weaknesses_conditions[:state].to_i]}"

        @filters << "<b>#{Finding.human_attribute_name('state')}</b> = \"#{state_text}\""
      end

      if params[:process_control_stats][:finding_title].present?
        weaknesses_conditions[:title] = params[:process_control_stats][:finding_title]

        @filters << "<b>#{Finding.human_attribute_name('title')}</b> = \"#{weaknesses_conditions[:title]}\""
      end
    end

    @periods.each do |period|
      review_identifications = []
      process_controls = {}
      reviews_score_data[period] ||= []

      conclusion_reviews.for_period(period).each do |c_r|
        control_objective_items = c_r.review.control_objective_items.
          not_excluded_from_score.
          for_business_units(*@business_unit_ids).
          with_best_practice_names(*@best_practices).
          with_process_control_names(*@process_controls)

        control_objective_items.each do |coi|
          coi_effectiveness = effectiveness coi
          pc_data = process_controls[coi.process_control.name] ||= {}
          pc_data[:weaknesses_ids] ||= {}
          pc_data[:reviews_with_weaknesses] ||= []
          id = coi.review.id
          pc_data[:review_ids] ||= []
          pc_data[:review_ids] << id if pc_data[:review_ids].exclude? id
          identification = coi.review.identification
          weaknesses_count = {}
          weaknesses = final ? coi.final_weaknesses : coi.weaknesses
          weaknesses = weaknesses.where(state: weaknesses_conditions[:state]) if weaknesses_conditions[:state]
          weaknesses = weaknesses.with_title(weaknesses_conditions[:title])   if weaknesses_conditions[:title]

          if review_identifications.exclude? identification
            review_identifications << identification
          end

          weaknesses.not_revoked.each do |w|
            @risk_levels |= RISK_TYPES.sort { |r1, r2| r2[1] <=> r1[1] }.map { |r| r.first }
            show = @business_unit_ids.blank? ||
              @business_unit_ids.include?(c_r.review.business_unit.id) ||
              w.business_unit_ids.any? { |bu_id| @business_unit_ids.include?(bu_id) }

            if show
              weaknesses_count[w.risk_text] ||= 0
              weaknesses_count[w.risk_text] += 1
              pc_data[:weaknesses_ids][w.risk_text] ||= []
              pc_data[:weaknesses_ids][w.risk_text] << w.id
            end
          end

          if weaknesses.not_revoked.size > 0 && pc_data[:reviews_with_weaknesses].exclude?(id)
            pc_data[:reviews_with_weaknesses] << id
          end

          pc_data[:weaknesses] ||= {}
          pc_data[:effectiveness] ||= []
          pc_data[:effectiveness] << coi_effectiveness

          reviews_score_data[period] << coi_effectiveness

          weaknesses_count.each do |r, c|
            pc_data[:weaknesses][r] ||= 0
            pc_data[:weaknesses][r] += c
          end

          process_controls[coi.process_control.name] = pc_data
        end
      end

      @review_identifications[period] = review_identifications.sort
      @reviews_score_data[period] = reviews_score_data[period].size > 0 ?
        weighted_average(reviews_score_data[period]) : 100

      @process_control_data[period] ||= []

      process_controls.each do |pc, pc_data|
        @process_control_ids_data[pc] ||= {}
        reviews_count = pc_data[:effectiveness].size
        effectiveness = reviews_count > 0 ? weighted_average(pc_data[:effectiveness]) : 100
        weaknesses_count = pc_data[:weaknesses]

        if weaknesses_count.values.sum == 0
          weaknesses_count_text = t(
            "#{@controller}_committee_report.process_control_stats.without_weaknesses")
        else
          weaknesses_count_text = []

          @risk_levels.each do |risk|
            risk_text = t("risk_types.#{risk}")
            text = "#{risk_text}: #{weaknesses_count[risk_text] || 0}"

            @process_control_ids_data[pc][text] = pc_data[:weaknesses_ids][risk_text]

            weaknesses_count_text << text
          end
        end

        @process_control_data[period] << {
          'process_control' => pc,
          'effectiveness' => effectiveness_label(effectiveness, pc_data[:reviews_with_weaknesses], pc_data[:review_ids]),
          'weaknesses_count' => weaknesses_count_text
        }
      end

      @process_control_data[period].sort! do |pc_data_1, pc_data_2|
        ef1 = pc_data_1['effectiveness'].match(/\d+.?\d+/)[0].to_f rescue 0.0
        ef2 = pc_data_2['effectiveness'].match(/\d+.?\d+/)[0].to_f rescue 0.0

        ef1 <=> ef2
      end
    end
  end

  def effectiveness_label(effectiveness, reviews_with_weaknesses, review_ids)
    effectiveness_label = []

   effectiveness_label << t(
      "#{@controller}_committee_report.process_control_stats.average_effectiveness_resume",
      :effectiveness => "#{'%.2f' % effectiveness}%",
      :count => review_ids.count
    )

    effectiveness_label <<  t(
      "#{@controller}_committee_report.process_control_stats.reviews_with_weaknesses",
      :count => reviews_with_weaknesses.count
    )

    effectiveness_label.join(' / ')
  end

  def create_process_control_stats
    self.process_control_stats

    pdf = init_pdf(params[:report_title], params[:report_subtitle])

    add_pdf_description(pdf, @controller, @from_date, @to_date)

    @periods.each do |period|
      add_period_title(pdf, period)

      column_data = []
      columns = {}
      column_widths, column_headers = [], []

      @columns.each do |col_name, col_title, col_width|
        column_headers << "<b>#{col_title}</b>"
        column_widths << pdf.percent_width(col_width)
      end

      @process_control_data[period].each do |row|
        new_row = []

        @columns.each do |col_name, _|
          new_row << (row[col_name].kind_of?(Array) ?
            row[col_name].map {|l| "  • #{l}"}.join("\n") :
            row[col_name])
        end

        column_data << new_row
      end

      unless column_data.blank?
        pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
          table_options = pdf.default_table_options(column_widths)

          pdf.table(column_data.insert(0, column_headers), table_options) do
            row(0).style(
              :background_color => 'cccccc',
              :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
            )
          end
        end
      else
        pdf.text(
          t("#{@controller}_committee_report.process_control_stats.without_audits_in_the_period"))
      end

      pdf.move_down PDF_FONT_SIZE
      pdf.text t(
        "#{@controller}_committee_report.process_control_stats.review_effectiveness_average",
        :score => @reviews_score_data[period]
      ), :inline_format => true

      pdf.move_down PDF_FONT_SIZE * 0.25
      pdf.text [
        Review.model_name.human(count: 0),
        @review_identifications[period].to_sentence
      ].join(': ') , :inline_format => true
    end

    add_pdf_filters(pdf, @controller, @filters) if @filters.present?

    save_pdf(pdf, @controller, @from_date, @to_date, 'process_control_stats')

    redirect_to_pdf(@controller, @from_date, @to_date, 'process_control_stats')
  end

  private

    def effectiveness coi
      if @business_unit_ids && @business_unit_ids.size == 1
        score = coi.business_unit_scores.where(business_unit_id: @business_unit_ids).take
      end

      _effectiveness = score ? score.effectiveness : coi.effectiveness

      [_effectiveness * coi.relevance, coi.relevance]
    end

    def weighted_average effectiveness
      scores  = effectiveness.map(&:first)
      weights = effectiveness.map(&:last)

      effectiveness.size > 0 ? (scores.sum.to_f / weights.sum).round(2) : 100
    end
end
