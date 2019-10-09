module Reports::ControlObjectiveStatsByReview
  include Reports::CommonControlObjectiveStats
  include Reports::Pdf
  include Reports::Period
  include Parameters::Risk

  def control_objective_stats_by_review
    init_control_objective_stats_by_review_vars

    if params[@action]
      conclusion_reviews_by_business_unit_type if params[@action][:business_unit_type].present?
      conclusion_reviews_by_business_unit      if params[@action][:business_unit].present?
      conclusion_reviews_by_control_objective  if params[@action][:control_objective].present?
      conclusion_reviews_by_finding_status     if params[@action][:finding_status].present?
      conclusion_reviews_by_finding_title      if params[@action][:finding_title].present?
    end

    @periods.each do |period|
      count_conclusion_review_weaknesses(period)

      @process_controls.each do |pc, cos|
        @control_objectives_data[period][pc] ||= {}

        cos.each do |co, data|
          @control_objectives_data[period][pc][co.name] ||= {}
          @coi_data = data

          @weaknesses_count = @coi_data[:weaknesses]

          if @weaknesses_count.values.sum == 0
            @weaknesses_count_text = t "#{@controller}_committee_report.control_objective_stats_by_review.without_weaknesses"
          else
            group_findings_by_risk(period, pc, co, @coi_data)
          end

          @process_control_data[period] << {
            'process_control' => pc,
            'control_objective' => co.name,
            'reviews' => @coi_data[:review_identifications].join("\n"),
            'weaknesses_count' => @weaknesses_count_text
          }
        end
      end

      sort_process_control_data(period)
    end
  end

  def create_control_objective_stats_by_review
    self.control_objective_stats_by_review

    pdf = init_pdf(params[:report_title], params[:report_subtitle])

    add_pdf_description(pdf, @controller, @from_date, @to_date)

    @periods.each do |period|
      add_period_title(pdf, period)

      prepare_pdf_table_headers(pdf)

      @process_control_data[period].each do |data|
        @column_data << prepare_pdf_table_row(data, period)
      end

      unless @column_data.blank?
        add_control_objective_stats_pdf_table(pdf)
      else
        pdf.text(
          t("#{@controller}_committee_report.control_objective_stats_by_review.without_audits_in_the_period"))
      end
    end

    add_pdf_filters(pdf, @controller, @filters) if @filters.present?

    save_pdf(pdf, @controller, @from_date, @to_date, 'control_objective_stats_by_review')

    redirect_to_pdf(@controller, @from_date, @to_date, 'control_objective_stats_by_review')
  end

  private

    def init_control_objective_stats_by_review_vars
      @controller = params[:controller_name]
      @action = :control_objective_stats_by_review
      @final = params[:final] == 'true'
      @title = t("#{@controller}_committee_report.control_objective_stats_title")
      @from_date, @to_date = *make_date_range(params[@action])
      @periods = periods_for_interval
      @risk_levels = []
      @risk_levels |= RISK_TYPES.sort { |r1, r2| r2[1] <=> r1[1] }.map { |r| r.first }
      @filters = []
      @columns = [
        ['process_control', BestPractice.human_attribute_name('process_controls.name'), 20],
        ['control_objective', ControlObjective.model_name.human, 40],
        ['reviews', Review.model_name.human(count: 0), 20],
        ['weaknesses_count', t('review.weaknesses_count_by_state'), 20]
      ]
      @conclusion_reviews = ConclusionFinalReview.list_all_by_date(
        @from_date, @to_date
      )
      @process_control_data = {}
      @control_objectives = []
      @control_objectives_data = {}
      @weaknesses_conditions = {}

      @periods.each do |period|
        @control_objectives_data[period] = {}
      end
    end

    def count_conclusion_review_weaknesses(period)
      @process_control_data[period] ||= []
      @process_controls = {}
      @weaknesses_status_count = {}

      @conclusion_reviews.for_period(period).each do |c_r|
        control_objective_items = c_r.review.control_objective_items.
          not_excluded_from_score.
          for_business_units(*@business_unit_ids).
          with_names(*@control_objectives)

        control_objective_items.each do |coi|
          init_control_objective_item_data(coi)

          count_weaknesses_by_risk(@weaknesses)

          @process_controls[coi.process_control.name][coi.control_objective] = @coi_data
        end
      end
    end

    def init_control_objective_item_data(coi)
      @process_controls[coi.process_control.name] ||= {}
      @coi_data = @process_controls[coi.process_control.name][coi.control_objective] || {}
      @coi_data[:weaknesses_ids] ||= {}
      @weaknesses_count = {}
      @weaknesses = @final ? coi.final_weaknesses.not_revoked : coi.weaknesses.not_revoked
      @weaknesses = @weaknesses.where(state: @weaknesses_conditions[:state]) if @weaknesses_conditions[:state]
      @weaknesses = @weaknesses.with_title(@weaknesses_conditions[:title])   if @weaknesses_conditions[:title]

      @coi_data[:weaknesses] ||= {}

      id = coi.review.id
      @coi_data[:review_ids] ||= []
      @coi_data[:review_ids] << id if @coi_data[:review_ids].exclude? id

      identification = coi.review.identification
      @coi_data[:review_identifications] ||= []

      if @coi_data[:review_identifications].exclude? identification
        @coi_data[:review_identifications] << identification
      end

      @coi_data[:reviews] ||= 0
      @coi_data[:reviews] += 1 if @weaknesses.size > 0
    end
end
