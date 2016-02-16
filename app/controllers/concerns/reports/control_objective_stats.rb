module Reports::ControlObjectiveStats
  include Reports::Pdf
  include Reports::Period
  include Parameters::Risk

  def control_objective_stats
    init_vars

    if params[:control_objective_stats]
      conclusion_reviews_by_business_unit_type if params[:control_objective_stats][:business_unit_type].present?
      conclusion_reviews_by_business_unit      if params[:control_objective_stats][:business_unit].present?
      conclusion_reviews_by_control_objective  if params[:control_objective_stats][:control_objective].present?
      conclusion_reviews_by_finding_status     if params[:control_objective_stats][:finding_status].present?
      conclusion_reviews_by_finding_title      if params[:control_objective_stats][:finding_title].present?
    end

    @periods.each do |period|
      count_conclusion_review_weaknesses(period)

      @process_controls.each do |pc, cos|
        @control_objectives_data[period][pc] ||= {}

        cos.each do |co, data|
          @control_objectives_data[period][pc][co.name] ||= {}
          @coi_data = data

          effectiveness = @coi_data[:effectiveness].size > 0 ?
            @coi_data[:effectiveness].sum.to_f / @coi_data[:effectiveness].size : 100
          @weaknesses_count = @coi_data[:weaknesses]

          if @weaknesses_count.values.sum == 0
            @weaknesses_count_text = t "#{@controller}_committee_report.control_objective_stats.without_weaknesses"
          else
            group_findings_by_risk(period, pc, co, @coi_data)
          end

          @process_control_data[period] << {
            'process_control' => pc,
            'control_objective' => co.name,
            'effectiveness' => get_effectiveness(effectiveness),
            'weaknesses_count' => @weaknesses_count_text
          }
        end
      end

      sort_process_control_data(period)
    end
  end

  def create_control_objective_stats
    self.control_objective_stats

    pdf = init_pdf(params[:report_title], params[:report_subtitle])

    add_pdf_description(pdf, @controller, @from_date, @to_date)

    @periods.each do |period|
      add_period_title(pdf, period)

      prepare_pdf_table_headers(pdf)

      @process_control_data[period].each do |data|
        @column_data << prepare_pdf_table_row(data, period)
      end

      unless @column_data.blank?
        add_pdf_table(pdf)
      else
        pdf.text(
          t("#{@controller}_committee_report.control_objective_stats.without_audits_in_the_period"))
      end

      pdf.move_down PDF_FONT_SIZE
      pdf.text t(
        "#{@controller}_committee_report.control_objective_stats.review_effectiveness_average",
        :score => @reviews_score_data[period]
      ), :inline_format => true
    end

    add_pdf_filters(pdf, @controller, @filters) if @filters.present?

    save_pdf(pdf, @controller, @from_date, @to_date, 'control_objective_stats')

    redirect_to_pdf(@controller, @from_date, @to_date, 'control_objective_stats')
  end

  private

    def init_vars
      @controller = params[:controller_name]
      @final = params[:final] == 'true'
      @title = t("#{@controller}_committee_report.control_objective_stats_title")
      @from_date, @to_date = *make_date_range(params[:control_objective_stats])
      @periods = periods_for_interval
      @risk_levels = []
      @risk_levels |= RISK_TYPES.sort { |r1, r2| r2[1] <=> r1[1] }.map { |r| r.first }
      @filters = []
      @columns = [
        ['process_control', BestPractice.human_attribute_name('process_controls.name'), 20],
        ['control_objective', ControlObjective.model_name.human, 40],
        ['effectiveness', t("#{@controller}_committee_report.control_objective_stats.average_effectiveness"), 20],
        ['weaknesses_count', t('review.weaknesses_count_by_state'), 20]
      ]
      @conclusion_reviews = ConclusionFinalReview.list_all_by_date(
        @from_date, @to_date
      )
      @process_control_data = {}
      @reviews_score_data = {}
      @control_objectives = []
      @control_objectives_data = {}
      @weaknesses_conditions = {}

      @periods.each do |period|
        @control_objectives_data[period] = {}
      end
    end

    def conclusion_reviews_by_business_unit_type
      @selected_business_unit = BusinessUnitType.find params[:control_objective_stats][:business_unit_type]
      @filters << "<b>#{BusinessUnitType.model_name.human}</b> = \"#{@selected_business_unit.name.strip}\""

      @conclusion_reviews = @conclusion_reviews.by_business_unit_type @selected_business_unit.id
    end

    def conclusion_reviews_by_business_unit
      business_units = params[:control_objective_stats][:business_unit].split(
        SPLIT_AND_TERMS_REGEXP
      ).uniq.map(&:strip)
      @business_unit_ids = business_units.present? && BusinessUnit.by_names(*business_units).pluck('id')

      if business_units.present?
        @filters << "<b>#{BusinessUnit.model_name.human}</b> = \"#{params[:control_objective_stats][:business_unit].strip}\""

        @conclusion_reviews = @conclusion_reviews.by_business_unit_names *business_units
      end
    end

    def conclusion_reviews_by_control_objective
      @control_objectives = params[:control_objective_stats][:control_objective].split(
        SPLIT_AND_TERMS_REGEXP
      ).uniq.map(&:strip)

      if @control_objectives.present?
        @filters << "<b>#{ControlObjective.model_name.human}</b> = \"#{params[:control_objective_stats][:control_objective].strip}\""

        @conclusion_reviews = @conclusion_reviews.by_control_objective_names *@control_objectives
      end
    end

    def conclusion_reviews_by_finding_status
      @weaknesses_conditions[:state] = params[:control_objective_stats][:finding_status]
      state_text = t "finding.status_#{Finding::STATUS.invert[@weaknesses_conditions[:state].to_i]}"

      @filters << "<b>#{Finding.human_attribute_name('state')}</b> = \"#{state_text}\""
    end

    def conclusion_reviews_by_finding_title
      @weaknesses_conditions[:title] = params[:control_objective_stats][:finding_title]

      @filters << "<b>#{Finding.human_attribute_name('title')}</b> = \"#{@weaknesses_conditions[:title]}\""
    end

    def get_effectiveness(effectiveness)
      effectiveness_label = []

      effectiveness_label << t(
        "#{@controller}_committee_report.control_objective_stats.average_effectiveness_resume",
        :effectiveness => "#{'%.2f' % effectiveness}%",
        :count => @coi_data[:review_ids].count
      )

      effectiveness_label <<  t(
        "#{@controller}_committee_report.control_objective_stats.reviews_with_weaknesses",
        :count => @coi_data[:reviews]
      )

      effectiveness_label.join(' / ')
    end

    def count_conclusion_review_weaknesses(period)
      @reviews_score_data[period] ||= []
      @process_control_data[period] ||= []
      @process_controls = {}
      @weaknesses_status_count = {}

      @conclusion_reviews.for_period(period).each do |c_r|
        _effectiveness = []

        c_r.review.control_objective_items.not_excluded_from_score.with_names(*@control_objectives).each do |coi|
          init_control_objective_item_data(coi)

          count_weaknesses_by_risk(@weaknesses)

          _effectiveness << [effectiveness(coi) * coi.relevance, coi.relevance]
          @process_controls[coi.process_control.name][coi.control_objective] = @coi_data
        end

        @reviews_score_data[period] << weighted_average(_effectiveness)
      end

      @reviews_score_data[period] = @reviews_score_data[period].size > 0 ?
        (@reviews_score_data[period].sum.to_f / @reviews_score_data[period].size).round : 100
    end

    def sort_process_control_data(period)
      @process_control_data[period].sort! do |pc_data_1, pc_data_2|
        ef1 = pc_data_1['effectiveness'].match(/\d+.?\d+/)[0].to_f rescue 0.0
        ef2 = pc_data_2['effectiveness'].match(/\d+.?\d+/)[0].to_f rescue 0.0

        ef1 <=> ef2
      end
    end

    def group_findings_by_risk(period, pc, co, coi_data)
      @weaknesses_count_text = {}
      text = {}

      @risk_levels.each do |risk|
        risk_text = t("risk_types.#{risk}")
        text[risk_text] ||= { :complete => 0, :incomplete => 0 }

        if @weaknesses_status_count[risk_text]
          text[risk_text][:incomplete] = @weaknesses_status_count[risk_text][:incomplete]
          text[risk_text][:complete] = @weaknesses_status_count[risk_text][:complete]
        end

        @control_objectives_data[period][pc][co.name][risk_text] ||= { :complete => [], :incomplete => [] }
        coi_data[:weaknesses_ids][risk_text] ||= { :complete => [], :incomplete => [] }
        @control_objectives_data[period][pc][co.name][risk_text][:complete].concat coi_data[:weaknesses_ids][risk_text][:complete]
        @control_objectives_data[period][pc][co.name][risk_text][:incomplete].concat coi_data[:weaknesses_ids][risk_text][:incomplete]
        @weaknesses_count_text[risk_text.to_sym] = text[risk_text]
      end
    end

    def count_weaknesses_by_risk(weaknesses)
      weaknesses.each do |w|
        show = @business_unit_ids.blank? ||
          @business_unit_ids.include?(w.review.business_unit.id) ||
          w.business_unit_ids.any? { |bu_id| @business_unit_ids.include?(bu_id) }

        if show
          @weaknesses_count[w.risk_text] ||= 0
          @weaknesses_count[w.risk_text] += 1

          @weaknesses_status_count[w.risk_text] ||= { :incomplete => 0, :complete => 0 }
          @coi_data[:weaknesses_ids][w.risk_text] ||= { :incomplete => [], :complete => [] }

          if Finding::PENDING_STATUS.include? w.state
            @weaknesses_status_count[w.risk_text][:incomplete] += 1
            @coi_data[:weaknesses_ids][w.risk_text][:incomplete] << w.id
          else
            @weaknesses_status_count[w.risk_text][:complete] += 1
            @coi_data[:weaknesses_ids][w.risk_text][:complete] << w.id
          end
        end

        @weaknesses_count.each do |r, c|
          @coi_data[:weaknesses][r] ||= 0
          @coi_data[:weaknesses][r] += c
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
      @coi_data[:effectiveness] ||= []
      @coi_data[:effectiveness] << effectiveness(coi)

      id = coi.review.id
      @coi_data[:review_ids] ||= []
      @coi_data[:review_ids] << id if @coi_data[:review_ids].exclude? id

      @coi_data[:reviews] ||= 0
      @coi_data[:reviews] += 1 if @weaknesses.size > 0
    end

    def effectiveness coi
      if coi.continuous && @business_unit_ids && @business_unit_ids.size == 1
        score = coi.business_unit_scores.where(
          business_unit_id: @business_unit_ids
        ).take
      end

      score ? score.effectiveness : coi.effectiveness
    end

    def weighted_average effectiveness
      scores  = effectiveness.map(&:first)
      weights = effectiveness.map(&:last)

      effectiveness.size > 0 ? (scores.sum / weights.sum).round : 100
    end

    def prepare_pdf_table_headers(pdf)
      @column_data, @column_headers, @column_widths = [], [], []

      @columns.each do |col_name, col_title, col_width|
        @column_headers << "<b>#{col_title}</b>"
        @column_widths << pdf.percent_width(col_width)
      end
    end

    def prepare_pdf_table_row(data, period)
      new_row = []

      @columns.each do |col_name, _|
        if data[col_name].kind_of?(Hash)
          list = ''
          @risk_levels.each do |risk|
            risk_text = t("risk_types.#{risk}")
            co = data["control_objective"]
            pc = data["process_control"]

            incompletes = @control_objectives_data[period][pc][co][risk_text][:incomplete].count
            completes = @control_objectives_data[period][pc][co][risk_text][:complete].count

            list += "  • #{risk_text}: #{incompletes} / #{completes} \n"
          end
          new_row << list
        else
          new_row << data[col_name]
        end
      end

      new_row
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
end
