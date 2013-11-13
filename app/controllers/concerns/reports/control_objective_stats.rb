module Reports::ControlObjectiveStats
  include Reports::Pdf
  include Reports::Period
  include Parameters::Risk

  def control_objective_stats
    @controller = params[:controller_name]
    final = params[:final]
    @title = t("#{@controller}_committee_report.control_objective_stats_title")
    @from_date, @to_date = *make_date_range(params[:control_objective_stats])
    @periods = periods_for_interval
    @risk_levels = []
    @filters = []
    @columns = [
      ['process_control', BestPractice.human_attribute_name(:process_controls), 20],
      ['control_objective', ControlObjective.model_name.human, 40],
      ['effectiveness', t("#{@controller}_committee_report.control_objective_stats.average_effectiveness"), 20],
      ['weaknesses_count', t('review.weaknesses_count_by_state'), 20]
    ]
    conclusion_reviews = ConclusionFinalReview.list_all_by_date(
      @from_date, @to_date
    )
    @process_control_data = {}
    @reviews_score_data = {}
    reviews_score_data = {}
    control_objectives = []
    @control_objectives_data = {}

    @periods.each do |period|
      @control_objectives_data[period] = {}
    end

    if params[:control_objective_stats]
      if params[:control_objective_stats][:business_unit_type].present?
        @selected_business_unit = BusinessUnitType.find(
          params[:control_objective_stats][:business_unit_type])
        conclusion_reviews = conclusion_reviews.by_business_unit_type(
          @selected_business_unit.id)
        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = " +
          "\"#{@selected_business_unit.name.strip}\""
      end

      if params[:control_objective_stats][:business_unit].present?
        business_units = params[:control_objective_stats][:business_unit].split(
          SPLIT_AND_TERMS_REGEXP
        ).uniq.map(&:strip)

        unless business_units.empty?
          conclusion_reviews = conclusion_reviews.by_business_unit_names(
            *business_units)
          @filters << "<b>#{BusinessUnit.model_name.human}</b> = " +
            "\"#{params[:control_objective_stats][:business_unit].strip}\""
        end
      end

      if params[:control_objective_stats][:control_objective].present?
        control_objectives =
          params[:control_objective_stats][:control_objective].split(
            SPLIT_AND_TERMS_REGEXP
          ).uniq.map(&:strip)

        unless control_objectives.empty?
          conclusion_reviews = conclusion_reviews.by_control_objective_names(
            *control_objectives)
          @filters << "<b>#{ControlObjective.model_name.human}</b> = " +
            "\"#{params[:control_objective_stats][:control_objective].strip}\""
        end
      end
    end

    @periods.each do |period|
      reviews_score_data[period] ||= []
      process_controls = {}
      weaknesses_status_count = {}

      conclusion_reviews.for_period(period).each do |c_r|
        c_r.review.control_objective_items.not_excluded_from_score.with_names(*control_objectives).each do |coi|
          process_controls[coi.process_control.name] ||= {}
          coi_data = process_controls[coi.process_control.name][coi.control_objective] || {}
          coi_data[:weaknesses_ids] ||= {}
          weaknesses_count = {}
          weaknesses = final ? coi.final_weaknesses : coi.weaknesses

          weaknesses.not_revoked.each do |w|
            @risk_levels |= RISK_TYPES.sort { |r1, r2| r2[1] <=> r1[1] }.map { |r| r.first }

            weaknesses_count[w.risk_text] ||= 0
            weaknesses_count[w.risk_text] += 1

            weaknesses_status_count[w.risk_text] ||= { :incomplete => 0, :complete => 0 }

            coi_data[:weaknesses_ids][w.risk_text] ||= { :incomplete => [], :complete => [] }

            if Finding::PENDING_STATUS.include? w.state
              weaknesses_status_count[w.risk_text][:incomplete] += 1
              coi_data[:weaknesses_ids][w.risk_text][:incomplete] << w.id
            else
              weaknesses_status_count[w.risk_text][:complete] += 1
              coi_data[:weaknesses_ids][w.risk_text][:complete] << w.id
            end
          end

          coi_data[:weaknesses] ||= {}
          coi_data[:effectiveness] ||= []
          coi_data[:effectiveness] << coi.effectiveness

          coi_data[:reviews] ||= 0
          coi_data[:reviews] += 1 if weaknesses.size > 0

          weaknesses_count.each do |r, c|
            coi_data[:weaknesses][r] ||= 0
            coi_data[:weaknesses][r] += c
          end

          process_controls[coi.process_control.name][coi.control_objective] = coi_data
        end

        reviews_score_data[period] << c_r.review.score
      end

      @reviews_score_data[period] = reviews_score_data[period].size > 0 ?
        (reviews_score_data[period].sum.to_f / reviews_score_data[period].size).round : 100

      @process_control_data[period] ||= []

      process_controls.each do |pc, cos|
        @control_objectives_data[period][pc] ||= {}

        cos.each do |co, coi_data|
          @control_objectives_data[period][pc][co.name] ||= {}

          reviews_count = coi_data[:reviews]
          effectiveness = coi_data[:effectiveness].size > 0 ?
            coi_data[:effectiveness].sum.to_f / coi_data[:effectiveness].size : 100
          weaknesses_count = coi_data[:weaknesses]

          if weaknesses_count.values.sum == 0
            weaknesses_count_text = t(
              "#{@controller}_committee_report.control_objective_stats.without_weaknesses")
          else
            weaknesses_count_text = {}
            text = {}

            @risk_levels.each do |risk|
              risk_text = t("risk_types.#{risk}")
              text[risk_text] ||= { :complete => 0, :incomplete => 0 }

              if weaknesses_status_count[risk_text]
                text[risk_text][:incomplete] = weaknesses_status_count[risk_text][:incomplete]
                text[risk_text][:complete] = weaknesses_status_count[risk_text][:complete]
              end

              @control_objectives_data[period][pc][co.name][risk_text] ||= { :complete => [], :incomplete => [] }
              coi_data[:weaknesses_ids][risk_text] ||= { :complete => [], :incomplete => [] }
              @control_objectives_data[period][pc][co.name][risk_text][:complete].concat coi_data[:weaknesses_ids][risk_text][:complete]
              @control_objectives_data[period][pc][co.name][risk_text][:incomplete].concat coi_data[:weaknesses_ids][risk_text][:incomplete]
              weaknesses_count_text[risk_text.to_sym] = text[risk_text]
            end
          end

          @process_control_data[period] << {
            'process_control' => pc,
            'control_objective' => co.name,
            'effectiveness' => t(
              'conclusion_committee_report.control_objective_stats.average_effectiveness_resume',
              :effectiveness => "#{'%.2f' % effectiveness}%", :count => reviews_count
            ),
            'weaknesses_count' => weaknesses_count_text
          }
        end
      end

      @process_control_data[period].sort! do |pc_data_1, pc_data_2|
        ef1 = pc_data_1['effectiveness'].match(/\d+.?\d+/)[0].to_f rescue 0.0
        ef2 = pc_data_2['effectiveness'].match(/\d+.?\d+/)[0].to_f rescue 0.0

        ef1 <=> ef2
      end
    end
  end

  def create_control_objective_stats
    self.control_objective_stats

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    add_pdf_description(pdf, @controller, @from_date, @to_date)

    @periods.each do |period|
      pdf.move_down PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :left

      pdf.move_down PDF_FONT_SIZE

      column_data = []
      columns = {}
      column_headers, column_widths = [], []

      @columns.each do |col_name, col_title, col_width|
        column_headers << "<b>#{col_title}</b>"
        column_widths << pdf.percent_width(col_width)
      end

      @process_control_data[period].each do |row|
        new_row = []

        @columns.each do |col_name, _|
          if row[col_name].kind_of?(Hash)
            list = ""
            @risk_levels.each do |risk|
              risk_text = t("risk_types.#{risk}")
              co = row["control_objective"]
              pc = row["process_control"]

              incompletes = @control_objectives_data[period][pc][co][risk_text][:incomplete].count
              completes = @control_objectives_data[period][pc][co][risk_text][:complete].count

              list += "  • #{risk_text}: #{incompletes} / #{completes} \n"
            end
            new_row << list
          else
            new_row << row[col_name]
          end
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
          t("#{@controller}_committee_report.control_objective_stats.without_audits_in_the_period"))
      end

      pdf.move_down PDF_FONT_SIZE
      pdf.text t(
        "#{@controller}_committee_report.control_objective_stats.review_score_average",
        :score => @reviews_score_data[period]
      ), :inline_format => true
    end

    unless @filters.empty?
      pdf.move_down PDF_FONT_SIZE
      pdf.text t("#{@controller}_committee_report.applied_filters",
        :filters => @filters.to_sentence, :count => @filters.size),
        :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full,
        :inline_format => true
    end

    pdf.custom_save_as(
      t("#{@controller}_committee_report.control_objective_stats.pdf_name",
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'control_objective_stats', 0)

    redirect_to Prawn::Document.relative_path(
      t("#{@controller}_committee_report.control_objective_stats.pdf_name",
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'control_objective_stats', 0)
  end
end
