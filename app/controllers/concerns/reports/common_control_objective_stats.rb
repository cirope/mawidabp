module Reports::CommonControlObjectiveStats
  private

    def conclusion_reviews_by_business_unit_type
      @selected_business_unit = BusinessUnitType.find params[@action][:business_unit_type]
      @filters << "<b>#{BusinessUnitType.model_name.human}</b> = \"#{@selected_business_unit.name.strip}\""

      @conclusion_reviews = @conclusion_reviews.by_business_unit_type @selected_business_unit.id
    end

    def conclusion_reviews_by_business_unit
      business_units = params[@action][:business_unit].split(
        SPLIT_AND_TERMS_REGEXP
      ).uniq.map(&:strip)
      @business_unit_ids = business_units.present? && BusinessUnit.list.by_names(*business_units).pluck('id')

      if business_units.present?
        @filters << "<b>#{BusinessUnit.model_name.human}</b> = \"#{params[@action][:business_unit].strip}\""

        @conclusion_reviews = @conclusion_reviews.by_business_unit_names *business_units
      end
    end

    def conclusion_reviews_by_control_objective
      @control_objectives = params[@action][:control_objective].split(
        SPLIT_AND_TERMS_REGEXP
      ).uniq.map(&:strip)

      if @control_objectives.present?
        @filters << "<b>#{ControlObjective.model_name.human}</b> = \"#{params[@action][:control_objective].strip}\""

        @conclusion_reviews = @conclusion_reviews.by_control_objective_names *@control_objectives
      end
    end

    def conclusion_reviews_by_finding_status
      @weaknesses_conditions[:state] = params[@action][:finding_status]
      state_text = t "findings.state.#{Finding::STATUS.invert[@weaknesses_conditions[:state].to_i]}"

      @filters << "<b>#{Finding.human_attribute_name('state')}</b> = \"#{state_text}\""
    end

    def conclusion_reviews_by_finding_title
      @weaknesses_conditions[:title] = params[@action][:finding_title]

      @filters << "<b>#{Finding.human_attribute_name('title')}</b> = \"#{@weaknesses_conditions[:title]}\""
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

    def add_control_objective_stats_pdf_table(pdf)
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
