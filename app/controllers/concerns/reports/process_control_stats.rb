module Reports::ProcessControlStats                                                                                                 
  include Reports::Pdf
  include Reports::Period
  include Parameters::Risk

  def process_control_stats
    @controller = params[:controller_name]
    final = params[:final]
    @title = t("#{@controller}_committee_report.process_control_stats_title")
    @from_date, @to_date = *make_date_range(params[:process_control_stats])
    @periods = periods_for_interval
    @risk_levels = []
    @filters = []
    @columns = [
      ['process_control', BestPractice.human_attribute_name(:process_controls), 60],
      ['effectiveness', t("#{@controller}_committee_report.process_control_stats.average_effectiveness"), 20],
      ['weaknesses_count', t('review.weaknesses_count'), 20]
    ]
    conclusion_reviews = ConclusionFinalReview.list_all_by_date(
      @from_date, @to_date
    )
    @process_control_data = {}
    @process_control_ids_data = {}
    @reviews_score_data = {}
    reviews_score_data = {}

    if params[:process_control_stats]
      unless params[:process_control_stats][:business_unit_type].blank?
        @selected_business_unit = BusinessUnitType.find(
          params[:process_control_stats][:business_unit_type])
        conclusion_reviews = conclusion_reviews.by_business_unit_type(
          @selected_business_unit.id)
        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = " +
          "\"#{@selected_business_unit.name.strip}\""
      end

      unless params[:process_control_stats][:business_unit].blank?
        business_units = params[:process_control_stats][:business_unit].split(
          SPLIT_AND_TERMS_REGEXP
        ).uniq.map(&:strip)

        unless business_units.empty?
          conclusion_reviews = conclusion_reviews.by_business_unit_names(
            *business_units)
          @filters << "<b>#{BusinessUnit.model_name.human}</b> = " +
            "\"#{params[:process_control_stats][:business_unit].strip}\""
        end
      end
    end

    @periods.each do |period|
      process_controls = {}
      reviews_score_data[period] ||= []

      conclusion_reviews.for_period(period).each do |c_r|
        c_r.review.control_objective_items.not_excluded_from_score.each do |coi|
          pc_data = process_controls[coi.process_control.name] ||= {}
          pc_data[:weaknesses_ids] ||= {}
          pc_data[:reviews] ||= []
          weaknesses_count = {}
          weaknesses = final ? coi.final_weaknesses : coi.weaknesses

          weaknesses.not_revoked.each do |w|
            @risk_levels |= RISK_TYPES.sort { |r1, r2| r2[1] <=> r1[1] }.map { |r| r.first }

            weaknesses_count[w.risk_text] ||= 0
            weaknesses_count[w.risk_text] += 1
            pc_data[:weaknesses_ids][w.risk_text] ||= []
            pc_data[:weaknesses_ids][w.risk_text] << w.id
          end

          pc_data[:reviews] << coi.review_id if weaknesses.size > 0

          pc_data[:weaknesses] ||= {}
          pc_data[:effectiveness] ||= []
          pc_data[:effectiveness] << coi.effectiveness

          weaknesses_count.each do |r, c|
            pc_data[:weaknesses][r] ||= 0
            pc_data[:weaknesses][r] += c
          end

          process_controls[coi.process_control.name] = pc_data
        end

        reviews_score_data[period] << c_r.review.score
      end

      @reviews_score_data[period] = reviews_score_data[period].size > 0 ?
        (reviews_score_data[period].sum.to_f / reviews_score_data[period].size).round : 100

      @process_control_data[period] ||= []

      process_controls.each do |pc, pc_data|
        @process_control_ids_data[pc] ||= {}
        reviews_count = pc_data[:effectiveness].size
        effectiveness = reviews_count > 0 ?
          pc_data[:effectiveness].sum.to_f / reviews_count : 100
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
          'effectiveness' => t(
            "#{@controller}_committee_report.process_control_stats.average_effectiveness_resume",
            :effectiveness => "#{'%.2f' % effectiveness}%",
            :count => pc_data[:reviews].uniq.size
          ),
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

  def create_process_control_stats
    self.process_control_stats

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header current_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_description_item(
      t("#{@controller}_committee_report.period.title"),
      t("#{@controller}_committee_report.period.range",
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_down PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :left

      pdf.move_down PDF_FONT_SIZE

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
      t("#{@controller}_committee_report.process_control_stats.pdf_name",
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'process_control_stats', 0)

    redirect_to Prawn::Document.relative_path(
      t("#{@controller}_committee_report.process_control_stats.pdf_name",
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'process_control_stats', 0)
  end
end
