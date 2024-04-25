module Reports::SynthesisReport
  include Reports::Pdf
  include Parameters::Risk

  def synthesis_report
    init_synthesis_vars

    if params[:synthesis_report]
      synthesis_business_unit_type_reviews if params[:synthesis_report][:business_unit_type].present?
      synthesis_business_unit_reviews if params[:synthesis_report][:business_unit].present?
      synthesis_reviews_by_scope if params[:synthesis_report][:scope].present?
    end

    @business_unit_types = @selected_business_unit ?
      [@selected_business_unit] : BusinessUnitType.allowed_business_unit_types.compact

    @periods.each do |period|
      @business_unit_types.each do |but|
        set_synthesis_columns(but)
        init_synthesis_report_business_unit_type_vars

        @conclusion_reviews.for_period(period).each do |c_r|
          if c_r.review.business_unit.business_unit_type_id == but.id
            set_synthesis_report_process_controls_data(c_r)
            set_synthesis_report_control_objectives_data(c_r)
            set_synthesis_report_column_data(c_r)
          end
        end

        sort_synthesis_report_column_data
        set_synthesis_report_audits_by_business_unit_data(period, but)
      end
    end
  end

  def create_synthesis_report
    synthesis_report

    pdf = init_pdf(params[:report_title], params[:report_subtitle])

    add_pdf_description(pdf, @controller, @from_date, @to_date)

    @periods.each do |period|
      add_period_title(pdf, period, :justify)
      add_synthesis_report_average_score(period, pdf) if !@selected_business_unit

      @audits_by_business_unit[period].each do |data|
        prepare_synthesis_columns(pdf, data[:columns])
        add_synthesis_report_pdf_titles(pdf, data[:external], data[:name])
        prepare_synthesis_rows(data[:column_data])

        if @column_data.present?
          add_synthesis_report_data(pdf)
          add_synthesis_report_score_data(pdf, data[:inherent_risks], data[:residual_risks], data[:business_units])
          add_synthesis_report_repeated_text(pdf, data[:repeated_count]) if @controller == 'follow_up'
        else
          pdf.text t("#{@controller}_committee_report.synthesis_report.without_audits_in_the_period"),
            :style => :italic
        end
      end
    end

    add_pdf_filters(pdf, @controller, @filters) if @filters.present?

    add_synthesis_report_pdf_references(pdf)

    save_pdf(pdf, @controller, @from_date, @to_date, 'synthesis_report')
    redirect_to_pdf(@controller, @from_date, @to_date, 'synthesis_report')
  end

  private

    def init_synthesis_vars
      @controller = params[:controller_name]
      @final = @controller == 'conclusion'
      @title = t("#{@controller}_committee_report.synthesis_report_title")
      @from_date, @to_date = *make_date_range(params[:synthesis_report])
      @periods = periods_for_interval
      @column_order = ['business_unit_report_name', 'review', 'score', 'inherent_risk',
                       'residual_risk','process_control', 'weaknesses_count',
                       'oportunities_count']
      @filters = []
      @risk_levels = []
      @audits_by_business_unit = {}
      @conclusion_reviews = ConclusionFinalReview.list_all_by_date(@from_date,
        @to_date)
    end

    def synthesis_business_unit_type_reviews
      @selected_business_unit = BusinessUnitType.find(
        params[:synthesis_report][:business_unit_type])
      @conclusion_reviews = @conclusion_reviews.by_business_unit_type(
        @selected_business_unit.id)
      @filters << "<b>#{BusinessUnitType.model_name.human}</b> = " +
        "\"#{@selected_business_unit.name.strip}\""
    end

    def synthesis_business_unit_reviews
      business_units = params[:synthesis_report][:business_unit].split(
        SPLIT_AND_TERMS_REGEXP
      ).uniq.map(&:strip)

      unless business_units.empty?
        @conclusion_reviews = @conclusion_reviews.by_business_unit_names(*business_units)
        @filters << "<b>#{BusinessUnit.model_name.human}</b> = " +
          "\"#{params[:synthesis_report][:business_unit].strip}\""
      end
    end

    def synthesis_reviews_by_scope
      scope = params[:synthesis_report][:scope]

      @conclusion_reviews = @conclusion_reviews.where(reviews: { scope: scope })
      @filters << "<b>#{Review.human_attribute_name 'scope'}</b> = \"#{scope}\""
    end

    def set_synthesis_columns(but)
      @columns = {'business_unit_report_name' => [but.business_unit_label, 10],
        'review' => [Review.model_name.human, 10],
        'score' => ["#{Review.human_attribute_name(:score)} (1)", 10],
        'inherent_risk' => ["#{t('conclusion_reports.synthesis_report.inherent_risk')}", 10],
        'residual_risk' => ["#{t('conclusion_reports.synthesis_report.residual_risk')}", 10],
        'process_control' => ["#{BestPractice.human_attribute_name('process_controls.name')} (2)", 16],
        'weaknesses_count' => ["#{t('conclusion_review.objectives_and_scopes').downcase.upcase_first} (3)", 28],
        'oportunities_count' => ["#{Weakness.model_name.human(count: 0)} (4)", 26]
      }
    end

    def init_synthesis_report_business_unit_type_vars
      @column_data = []
      @review_scores = []
      @inherent_risk = []
      @residual_risk = []
      @business_unit_names = []
      @repeated_count = 0 if @controller == 'follow_up'
    end

    def set_synthesis_report_process_controls_data(c_r)
      @process_controls = {}

      c_r.review.control_objective_items_for_score.each do |coi|
        @process_controls[coi.process_control.name] ||= []
        @process_controls[coi.process_control.name] << coi
      end

      @process_controls.each do |pc, control_objective_items|
        coi_count = control_objective_items.inject(0.0) do |acc, coi|
          acc + (coi.relevance || 0)
        end
        total = control_objective_items.inject(0.0) do |acc, coi|
          acc + coi.effectiveness * (coi.relevance || 0)
        end

        @process_controls[pc] = coi_count > 0 ?
          (total / coi_count.to_f).round : 100
      end
    end

    def set_synthesis_report_control_objectives_data(c_r)
      @control_objective_text = []

      c_r.review.grouped_control_objective_items.each do |process_control, cois|
        @control_objective_text << [process_control.name, cois.sort.map(&:to_s)]
      end
    end

    def get_synthesis_report_process_controls_text
      @process_controls.sort do |pc1, pc2|
        pc1[1] <=> pc2[1]
      end.map { |pc| "#{pc[0]} (#{'%.2f' % pc[1]}%)" }
    end

    def get_synthesis_report_weaknesses_text(c_r)
      weaknesses_text = []

      c_r.review.grouped_control_objective_items.each do |process_control, cois|
        cois.sort.each do |coi|
          weaknesses = @final ? coi.final_weaknesses : coi.weaknesses

          weaknesses.not_revoked.sort_for_review.each do |w|
            weaknesses_text << w.title
          end
        end
      end

      weaknesses_text
    end

    def set_synthesis_report_column_data(c_r)
      process_control_text = get_synthesis_report_process_controls_text
      weaknesses_text = get_synthesis_report_weaknesses_text(c_r)

      @review_scores << c_r.review.score
      @column_data << [
        set_synthesis_report_business_unit_names(c_r.review),
        c_r.review.to_s,
        c_r.review.reload,
        set_synthesis_report_inherent_risk(c_r.review),
        set_synthesis_report_residual_risk(c_r.review),
        process_control_text,
        @control_objective_text,
        weaknesses_text.blank? ?
          t('follow_up_committee_report.synthesis_report.without_weaknesses') : weaknesses_text
      ]
    end

    def set_synthesis_report_business_unit_names review
      bu = review.business_unit.name

      @business_unit_names << bu

      bu
    end

    def set_synthesis_report_inherent_risk review
      risk = review.plan_item&.risk_assessment_item&.risk.to_f

      @inherent_risk << risk

      risk
    end

    def set_synthesis_report_residual_risk review
      risk = review.plan_item&.risk_assessment_item&.risk.to_f

      item_risk = risk * review.score.to_f / 100

      @residual_risk << item_risk

      item_risk
    end

    def sort_synthesis_report_column_data
      @column_data.sort! do |cd_1, cd_2|
        cd_1[2].score <=> cd_2[2].score
      end

      @column_data.each do |data|
        data[2] = data[2].score_text
      end
    end

    def set_synthesis_report_audits_by_business_unit_data(period, but)
      @audits_by_business_unit[period] ||= []
      @audits_by_business_unit[period] << {
        :name => but.name,
        :business_units => @business_unit_names.uniq.join(', '),
        :external => but.external,
        :columns => @columns,
        :column_data => @column_data,
        :review_scores => @review_scores,
        :inherent_risks => @inherent_risk,
        :residual_risks => @residual_risk,
        :repeated_count => @repeated_count
      }
    end

    def add_synthesis_report_data(pdf)
      @column_data.each do |row|
        row.each_with_index do |text, index|
          pdf.add_description_item @column_headers[index], text, 0, false
        end

        pdf.put_hr
      end
    end

    def prepare_synthesis_rows(column_data)
      @column_data = []

      column_data.each do |row|
        new_row = []

        row.each do |column|
          new_row << prepare_synthesis_column(column)
        end

        @column_data << new_row
      end
    end

    def prepare_synthesis_column(column, indent: 2)
      if column.kind_of?(Array)
        list = column.map do |l|
          if l.kind_of?(Array) && l.first.kind_of?(String) && l.second.kind_of?(Array)
            children = prepare_synthesis_column l.second, indent: indent + 2

            "#{Prawn::Text::NBSP * indent}<i>#{l.first}</i>#{children}"
          else
            "#{Prawn::Text::NBSP * indent}• #{l}"
          end
        end

        "\n#{list.join "\n"}"
      else
        column
      end
    end

    def add_synthesis_report_pdf_references(pdf)
      pdf.move_down PDF_FONT_SIZE

      references = t("#{@controller}_committee_report.synthesis_report.references", :risk_types => @risk_levels.to_sentence)

      pdf.text references, :font_size => (PDF_FONT_SIZE * 0.75).round,
        :align => :justify
    end

    def add_synthesis_report_repeated_text(pdf, repeated_count)
      pdf.text(t('follow_up_committee_report.synthesis_report.repeated_count',
        :count => repeated_count), :font_size => PDF_FONT_SIZE) if repeated_count > 0
    end

    def add_synthesis_report_score_data(pdf, inherent_risks, residual_risks, audit_type_name)
      inherent_risks_sum = inherent_risks.sum.to_f
      residual_risks_sum = residual_risks.sum.to_f

      if inherent_risks_sum > 0 && residual_risks_sum > 0
        title = t("#{@controller}_committee_report.synthesis_report.generic_score_average",
          :count => inherent_risks.size, :audit_type => audit_type_name)
        text = "<b>#{title}</b>: <i>#{(residual_risks_sum / inherent_risks_sum * 100).round}%</i>"
      else
        text = t('conclusion_committee_report.synthesis_report.without_audits_in_the_period')
      end

      pdf.move_down PDF_FONT_SIZE

      pdf.text text, :font_size => PDF_FONT_SIZE, :inline_format => true
    end

    def add_synthesis_report_average_score(period, pdf)
      unless @audits_by_business_unit[period].blank?
        count = 0

        internal_audits_by_business_unit = @audits_by_business_unit[period].reject do |but|
          but[:external]
        end

        total = internal_audits_by_business_unit.inject(0) do |sum, data|
          inherent_risks = data[:inherent_risks].sum
          residual_risks = data[:residual_risks].sum

          if inherent_risks > 0 && residual_risks > 0
            count += 1
            sum + (residual_risks / inherent_risks * 100).round
          else
            sum
          end
        end

        average_score = count > 0 ? (total.to_f / count).round : 100
      end

      add_synthesis_report_pdf_score(pdf, period, average_score)
    end

    def add_synthesis_report_pdf_score(pdf, period, average_score)
      pdf.move_down PDF_FONT_SIZE

      pdf.add_title(
        t(
          'follow_up_committee_report.synthesis_report.organization_score',
          :score => average_score || 100
        ),
        (PDF_FONT_SIZE * 1.1).round
      )

      pdf.move_down((PDF_FONT_SIZE * 0.75).round)

      pdf.text(
        t('follow_up_committee_report.synthesis_report.organization_score_note',
          :audit_types =>
            @audits_by_business_unit[period].map { |data|
              data[:name]
            }.to_sentence),
        :font_size => (PDF_FONT_SIZE * 0.75).round)
    end

    def prepare_synthesis_columns(pdf, columns)
      @column_headers = @column_order.map do |col_name|
        "<b>#{columns[col_name].first}</b>"
      end
    end

    def add_synthesis_report_pdf_titles(pdf, external, but_name)
      if external && !@internal_title_showed
        title = t "#{@controller}_committee_report.synthesis_report.internal_audit_weaknesses"
        @internal_title_showed = true
      elsif external && !@external_title_showed
        title = t "#{@controller}_committee_report.synthesis_report.external_audit_weaknesses"
        @external_title_showed = true
      end

      if title
        pdf.move_down PDF_FONT_SIZE * 2
        pdf.add_title title, (PDF_FONT_SIZE * 1.25).round, :center
      end

      pdf.add_subtitle but_name, PDF_FONT_SIZE, PDF_FONT_SIZE
    end
end
