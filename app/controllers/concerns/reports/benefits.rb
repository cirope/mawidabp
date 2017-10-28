module Reports::Benefits
  include Reports::Pdf
  include Reports::Period

  def benefits
    init_benefit_vars

    if params[:benefits]
      benefits_conclusion_reviews_by_business_unit_type if params[:benefits][:business_unit_type].present?
      benefits_conclusion_reviews_by_business_unit      if params[:benefits][:business_unit].present?
      benefits_conclusion_reviews_by_control_objective  if params[:benefits][:control_objective].present?
      benefits_conclusion_reviews_by_finding_status     if params[:benefits][:finding_status].present?
      benefits_conclusion_reviews_by_finding_title      if params[:benefits][:finding_title].present?
    end

    @periods.each do |period|
      extract_benefits period
    end
  end

  def create_benefits
    self.benefits

    pdf = init_pdf(params[:report_title], params[:report_subtitle])

    add_pdf_description(pdf, @controller, @from_date, @to_date)

    @periods.each do |period|
      add_period_title(pdf, period)

      prepare_pdf_table_headers(pdf)

      @benefits_data[period].each do |data|
        @column_data << prepare_benefit_pdf_table_row(data, period)
      end

      unless @column_data.blank?
        add_pdf_benefit_table(pdf)

        pdf.move_down PDF_FONT_SIZE
        pdf.text t(
          "#{@controller}_committee_report.benefits.total",
          amount: @benefits_total_data[period]
        ), inline_format: true
      else
        pdf.text t("#{@controller}_committee_report.benefits.without_audits_in_the_period")
      end
    end

    add_pdf_filters(pdf, @controller, @filters) if @filters.present?

    save_pdf(pdf, @controller, @from_date, @to_date, 'benefits')

    redirect_to_pdf(@controller, @from_date, @to_date, 'benefits')
  end

  private

    def init_benefit_vars
      @controller = params[:controller_name]
      @final = params[:final] == 'true'
      @title = t("#{@controller}_committee_report.benefits_title")
      @from_date, @to_date = *make_date_range(params[:benefits])
      @periods = periods_for_interval
      @filters = []
      @weaknesses_conditions = {}
      @columns = [
        ['finding', Finding.model_name.human, 20],
        ['benefit', Benefit.model_name.human, 20],
        ['benefit_type', Benefit.human_attribute_name('kind'), 10],
        ['amount', Achievement.human_attribute_name('amount'), 20],
        ['comment', Achievement.human_attribute_name('comment'), 30]
      ]
      @conclusion_reviews = ConclusionFinalReview.list_all_by_date(
        @from_date, @to_date
      )
      @benefits_data = {}
      @benefits_total_data = {}
    end

    def extract_benefits period
      @benefits_data[period] ||= []

      @conclusion_reviews.for_period(period).each do |c_r|
        total = 0
        weaknesses = @final ? c_r.review.final_weaknesses : c_r.review.weaknesses
        weaknesses = weaknesses.with_achievements.not_revoked
        weaknesses = weaknesses.where(state: @weaknesses_conditions[:state]) if @weaknesses_conditions[:state]
        weaknesses = weaknesses.with_title(@weaknesses_conditions[:title])   if @weaknesses_conditions[:title]

        weaknesses.each do |weakness|
          weakness.achievements.each do |achievement|
            @benefits_data[period] << {
              'finding' => weakness.to_s,
              'benefit' => achievement.benefit.to_s,
              'benefit_type' => I18n.t("benefits.kinds.#{achievement.benefit.kind}"),
              'amount' => achievement.signed_amount,
              'comment' => achievement.comment
            }

            total += achievement.signed_amount if achievement.amount
          end
        end

        @benefits_total_data[period] = total
      end
    end

    def benefits_conclusion_reviews_by_business_unit_type
      selected_business_unit = BusinessUnitType.find params[:benefits][:business_unit_type]

      @filters << "<b>#{BusinessUnitType.model_name.human}</b> = \"#{selected_business_unit.name.strip}\""

      @conclusion_reviews = @conclusion_reviews.by_business_unit_type selected_business_unit.id
    end

    def benefits_conclusion_reviews_by_business_unit
      business_units = params[:benefits][:business_unit].split(
        SPLIT_AND_TERMS_REGEXP
      ).uniq.map(&:strip)

      if business_units.present?
        @filters << "<b>#{BusinessUnit.model_name.human}</b> = \"#{params[:benefits][:business_unit].strip}\""

        @conclusion_reviews = @conclusion_reviews.by_business_unit_names *business_units
      end
    end

    def benefits_conclusion_reviews_by_control_objective
      @control_objectives = params[:benefits][:control_objective].split(
        SPLIT_AND_TERMS_REGEXP
      ).uniq.map(&:strip)

      if @control_objectives.present?
        @filters << "<b>#{ControlObjective.model_name.human}</b> = \"#{params[:benefits][:control_objective].strip}\""

        @conclusion_reviews = @conclusion_reviews.by_control_objective_names *@control_objectives
      end
    end

    def benefits_conclusion_reviews_by_finding_status
      @weaknesses_conditions[:state] = params[:benefits][:finding_status]
      state_text = t "findings.state.#{Finding::STATUS.invert[@weaknesses_conditions[:state].to_i]}"

      @filters << "<b>#{Finding.human_attribute_name('state')}</b> = \"#{state_text}\""
    end

    def benefits_conclusion_reviews_by_finding_title
      @weaknesses_conditions[:title] = params[:benefits][:finding_title]

      @filters << "<b>#{Finding.human_attribute_name('title')}</b> = \"#{@weaknesses_conditions[:title]}\""
    end

    def prepare_benefit_pdf_table_row(data, period)
      new_row = []

      @columns.each do |col_name, _|
        new_row << data[col_name]
      end

      new_row
    end

    def add_pdf_benefit_table(pdf)
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(@column_widths)

        pdf.table(@column_data.insert(0, @column_headers), table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end
end
