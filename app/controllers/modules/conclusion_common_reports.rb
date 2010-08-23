module ConclusionCommonReports
  def weaknesses_by_state
    @title = t :'conclusion_committee_report.weaknesses_by_state_title'
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_state])
    @periods = periods_for_interval
    @audit_types = [:internal, :external]
    @weaknesses_counts = {}
    @status = Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).
        sort { |s1, s2| s1.last <=> s2.last }

    @periods.each do |period|
      @audit_types.each do |audit_type|
        @weaknesses_counts[period] ||= {}
        @weaknesses_counts[period]["#{audit_type}_weaknesses"] =
          Weakness.list_all_by_date(@from_date, @to_date).send(
            "#{audit_type}_audit").for_period(period).finals(true).count(
            :group => :state)
        @weaknesses_counts[period]["#{audit_type}_oportunities"] =
          Oportunity.list_all_by_date(@from_date, @to_date).send(
            "#{audit_type}_audit").for_period(period).finals(true).count(
            :group => :state)
      end
    end
  end

  def create_weaknesses_by_state
    self.weaknesses_by_state

    pdf = PDF::Writer.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE * 2

    pdf.add_description_item(
      t(:'conclusion_committee_report.period.title'),
      t(:'conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_title "#{Period.human_name}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :justify

      @audit_types.each do |type|
        weaknesses_count = @weaknesses_counts[period]["#{type}_weaknesses"]
        oportunities_count = @weaknesses_counts[period]["#{type}_oportunities"]
        total_weaknesses = weaknesses_count.values.sum
        total_oportunities = oportunities_count.values.sum

        pdf.move_pointer PDF_FONT_SIZE * 2

        pdf.add_title t("conclusion_committee_report.findings_type_#{type}"),
          (PDF_FONT_SIZE * 1.25).round, :center

        pdf.move_pointer PDF_FONT_SIZE

        if (total_weaknesses + total_oportunities) > 0
          columns = {
            'state' => [Finding.human_attribute_name('state'), 30],
            'weaknesses_count' => [
              t(:'conclusion_committee_report.weaknesses_by_state.weaknesses_column'),
              type == :internal ? 35 : 70]
          }
          column_data = []

          if type == :internal
            columns['oportunities_count'] = [
              t(:'conclusion_committee_report.weaknesses_by_state.oportunities_column'), 35]
          end

          columns.each do |col_name, col_data|
            columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |column|
              column.heading = col_data.first
              column.width = pdf.percent_width col_data.last
            end
          end

          @status.each do |state|
            w_count = weaknesses_count[state.last] || 0
            o_count = oportunities_count[state.last] || 0
            weaknesses_percentage = total_weaknesses > 0 ?
              w_count.to_f / total_weaknesses * 100 : 0.0
            oportunities_percentage = total_oportunities > 0 ?
              o_count.to_f / total_oportunities * 100 : 0.0

            column_data << {
              'state' => t("finding.status_#{state.first}").to_iso,
              'weaknesses_count' =>
                "#{w_count} (#{'%.2f' % weaknesses_percentage.round(2)}%)",
              'oportunities_count' =>
                "#{o_count} (#{'%.2f' % oportunities_percentage.round(2)}%)",
            }
          end

          column_data << {
            'state' =>
              "<b>#{t(:'conclusion_committee_report.weaknesses_by_state.total')}</b>".to_iso,
            'weaknesses_count' => "<b>#{total_weaknesses}</b>",
            'oportunities_count' => "<b>#{total_oportunities}</b>"
          }

          unless column_data.blank?
            PDF::SimpleTable.new do |table|
              table.width = pdf.page_usable_width
              table.columns = columns
              table.data = column_data
              table.column_order = type == :internal ?
                ['state', 'weaknesses_count', 'oportunities_count'] :
                ['state', 'weaknesses_count']
              table.split_rows = true
              table.font_size = PDF_FONT_SIZE
              table.row_gap = (PDF_FONT_SIZE * 0.5).round
              table.shade_rows = :none
              table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
              table.heading_font_size = PDF_FONT_SIZE
              table.shade_headings = true
              table.bold_headings = true
              table.position = :left
              table.orientation = :right
              table.show_lines = :all
              table.render_on pdf
            end
          end
        else
          pdf.text t(:'follow_up_committee.without_weaknesses'),
            :font_size => PDF_FONT_SIZE
        end
      end
    end

    pdf.custom_save_as(
      t(:'conclusion_committee_report.weaknesses_by_state.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)),
      'conclusion_weaknesses_by_state', 0)

    redirect_to PDF::Writer.relative_path(
      t(:'conclusion_committee_report.weaknesses_by_state.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)),
      'conclusion_weaknesses_by_state', 0)
  end

  def weaknesses_by_risk
    @title = t :'conclusion_committee_report.weaknesses_by_risk_title'
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_risk])
    @periods = periods_for_interval
    @audit_types = [:internal, :external]
    @tables_data = {}
    risk_levels = parameter_in(@auth_organization.id,
      :admin_finding_risk_levels, @from_date)
    statuses = Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).
      sort { |s1, s2| s1.last <=> s2.last }

    @periods.each do |period|
      @audit_types.each do |audit_type|
        weaknesses_count = {}
        weaknesses_count_by_risk = {}

        risk_levels.each do |rl|
          weaknesses_count_by_risk[rl[0]] = 0

          statuses.each do |s|
            weaknesses_count[s[1]] ||= {}
            weaknesses_count[s[1]][rl[1]] = Weakness.list_all_by_date(@from_date,
              @to_date).send("#{audit_type}_audit").for_period(period).finals(
              true).count(:conditions => {:state => s[1], :risk => rl[1]})
            weaknesses_count_by_risk[rl[0]] += weaknesses_count[s[1]][rl[1]]
          end
        end

        @tables_data[period] ||= {}
        @tables_data[period][audit_type] = get_weaknesses_synthesis_table_data(
          weaknesses_count, weaknesses_count_by_risk, risk_levels)
      end
    end
  end

  def create_weaknesses_by_risk
    self.weaknesses_by_risk

    pdf = PDF::Writer.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE * 2

    pdf.add_description_item(
      t(:'conclusion_committee_report.period.title'),
      t(:'conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_title "#{Period.human_name}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :justify
      
      @audit_types.each do |type|
        pdf.move_pointer PDF_FONT_SIZE * 2

        pdf.add_title t("conclusion_committee_report.weaknesses_type_#{type}"),
          (PDF_FONT_SIZE * 1.25).round, :center

        pdf.move_pointer PDF_FONT_SIZE

        add_weaknesses_synthesis_table(pdf, @tables_data[period][type])
      end
    end

    pdf.custom_save_as(
      t(:'conclusion_committee_report.weaknesses_by_risk.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)),
      'conclusion_weaknesses_by_risk', 0)

    redirect_to PDF::Writer.relative_path(
      t(:'conclusion_committee_report.weaknesses_by_risk.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)),
      'conclusion_weaknesses_by_risk', 0)
  end

  def weaknesses_by_audit_type
    @title = t :'conclusion_committee_report.weaknesses_by_audit_type_title'
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_audit_type])
    @periods = periods_for_interval
    @audit_types = [:internal, :external]
    @data = {}
    risk_levels = parameter_in(@auth_organization.id,
      :admin_finding_risk_levels, @from_date)
    statuses = Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).
      sort { |s1, s2| s1.last <=> s2.last }

    @periods.each do |period|
      @data[period] ||= {}

      @audit_types.each do |audit_type|
        @data[period][audit_type] = []
        reviews_by_audit_type = {}
        conclusion_final_review = ConclusionFinalReview.list_all_by_date(
          @from_date, @to_date).send("#{audit_type}_audit").for_period(period)

        conclusion_final_review.each do |cfr|
          business_unit = cfr.review.plan_item.business_unit
          business_unit_type = business_unit.business_unit_type.name

          reviews_by_audit_type[business_unit_type] ||= {}
          reviews_by_audit_type[business_unit_type][business_unit.name] ||= []
          reviews_by_audit_type[business_unit_type][business_unit.name] << cfr
        end

        reviews_by_audit_type.each do |bu_type, bu_data|
          title = "#{Review.human_attribute_name('audit_type')}: #{bu_type}"
          business_units = {}

          bu_data.values.each do |cfrs|
            unless cfrs.empty?
              business_unit = cfrs.first.plan_item.business_unit
              weaknesses = []
              oportunities = []

              cfrs.sort! do |cfr1, cfr2|
                cfr1.review.effectiveness <=> cfr2.review.effectiveness
              end

              cfrs.each do |cfr|
                review = cfr.review
                weaknesses |= review.final_weaknesses
                oportunities |= review.final_oportunities
              end

              grouped_weaknesses = weaknesses.group_by(&:state)
              grouped_oportunities = oportunities.group_by(&:state)
              oportunities_table_data = []
              weaknesses_count = {}
              weaknesses_count_by_risk = {}
              total_oportunities = grouped_oportunities.values.sum(&:size)

              if total_oportunities > 0
                statuses.each do |s|
                  o_count = (grouped_oportunities[s[1]] || []).size
                  oportunities_percentage = total_oportunities > 0 ?
                    o_count.to_f / total_oportunities * 100 : 0.0

                  oportunities_table_data << {
                    'state' => "<b>#{t("finding.status_#{s[0]}")}</b>".to_iso,
                    'count' =>
                      "#{o_count} (#{'%.2f' % oportunities_percentage.round(2)}%)"
                  }
                end

                oportunities_table_data << {
                  'state' =>
                    "<b>#{t(:'conclusion_committee_report.weaknesses_by_audit_type.total')}</b>".to_iso,
                  'count' => "<b>#{total_oportunities}</b>"
                }
              end

              risk_levels.each do |rl|
                weaknesses_count_by_risk[rl[0]] = 0

                statuses.each do |s|
                  weaknesses_for_status = grouped_weaknesses[s[1]] || {}

                  count_for_risk = weaknesses_for_status.inject(0) do |sum, w|
                    sum + (w.risk == rl[1] ? 1 : 0)
                  end

                  weaknesses_count[s[1]] ||= {}
                  weaknesses_count[s[1]][rl[1]] = count_for_risk
                  weaknesses_count_by_risk[rl[0]] += weaknesses_count[s[1]][rl[1]]
                end
              end

              weaknesses_table_data = get_weaknesses_synthesis_table_data(
                weaknesses_count, weaknesses_count_by_risk, risk_levels)

              business_units[business_unit] = {
                :conclusion_reviews => cfrs,
                :weaknesses_table_data => weaknesses_table_data,
                :oportunities_table_data => oportunities_table_data
              }
            end
          end

          @data[period][audit_type] << {
            :title => title,
            :business_units => business_units
          }
        end
      end
    end
  end

  def create_weaknesses_by_audit_type
    self.weaknesses_by_audit_type

    pdf = PDF::Writer.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE * 2

    pdf.add_description_item(
      t(:'conclusion_committee_report.period.title'),
      t(:'conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_title "#{Period.human_name}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :justify
      
      @audit_types.each do |type|
        pdf.move_pointer PDF_FONT_SIZE * 2

        pdf.add_title t("conclusion_committee_report.findings_type_#{type}"),
          (PDF_FONT_SIZE * 1.25).round, :center

        pdf.move_pointer PDF_FONT_SIZE

        unless @data[period][type].blank?
          @data[period][type].each do |data_item|
            pdf.move_pointer PDF_FONT_SIZE
            pdf.add_title data_item[:title], PDF_FONT_SIZE, :center

            data_item[:business_units].each do |bu, bu_data|
              pdf.move_pointer PDF_FONT_SIZE

              pdf.add_description_item(
                bu.business_unit_type.business_unit_label, bu.name)
              pdf.move_pointer PDF_FONT_SIZE

              pdf.text "<b>#{t(:'actioncontroller.reviews')}</b>"
              pdf.move_pointer PDF_FONT_SIZE

              bu_data[:conclusion_reviews].each do |cr|
                findings_count = cr.review.final_weaknesses.size +
                  cr.review.final_oportunities.size

                text = "<C:bullet /> <b>#{cr.review}</b>: " +
                  cr.review.score_text

                if findings_count == 0
                  text << " (#{t(:'conclusion_committee_report.weaknesses_by_audit_type.without_weaknesses')})"
                end

                pdf.text text, :left => PDF_FONT_SIZE * 2
              end

              pdf.move_pointer PDF_FONT_SIZE

              pdf.add_title(
                t(:'conclusion_committee_report.weaknesses_by_audit_type.weaknesses'),
                PDF_FONT_SIZE)

              pdf.move_pointer PDF_FONT_SIZE

              add_weaknesses_synthesis_table(pdf,
                bu_data[:weaknesses_table_data], 10)

              if type == :internal
                pdf.move_pointer PDF_FONT_SIZE

                pdf.add_title(
                  t(:'conclusion_committee_report.weaknesses_by_audit_type.oportunities'),
                  PDF_FONT_SIZE)

                pdf.move_pointer PDF_FONT_SIZE

                unless bu_data[:oportunities_table_data].blank?
                  columns = {
                    'state' => [Oportunity.human_attribute_name('state'), 30],
                    'count' => [Oportunity.human_attribute_name('count'), 70]
                  }

                  columns.each do |col_name, col_data|
                    columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |column|
                      column.heading = col_data.first
                      column.width = pdf.percent_width col_data.last
                    end
                  end

                  PDF::SimpleTable.new do |table|
                    table.width = pdf.page_usable_width
                    table.columns = columns
                    table.data = bu_data[:oportunities_table_data]
                    table.column_order = ['state', 'count']
                    table.split_rows = true
                    table.font_size = (PDF_FONT_SIZE * 0.75).round
                    table.row_gap = (PDF_FONT_SIZE * 0.5).round
                    table.shade_rows = :none
                    table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
                    table.heading_font_size = PDF_FONT_SIZE
                    table.shade_headings = true
                    table.bold_headings = true
                    table.position = :left
                    table.orientation = :right
                    table.show_lines = :all
                    table.render_on pdf
                  end
                else
                  pdf.text t(:'follow_up_committee.without_oportunities')
                end
              end
            end
          end
        else
          pdf.text t(:'follow_up_committee.without_weaknesses'),
            :font_size => PDF_FONT_SIZE
        end
      end
    end

    pdf.custom_save_as(
      t(:'conclusion_committee_report.weaknesses_by_audit_type.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)),
      'conclusion_weaknesses_by_audit_type', 0)

    redirect_to PDF::Writer.relative_path(
      t(:'conclusion_committee_report.weaknesses_by_audit_type.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)),
      'conclusion_weaknesses_by_audit_type', 0)
  end

  private

  def periods_for_interval
    Period.all({
        :include => {:reviews => :conclusion_final_review},
        :conditions => [
          "#{ConclusionFinalReview.table_name}.issue_date BETWEEN :from_date AND :to_date",
          { :from_date => @from_date, :to_date => @to_date }
        ]
    })
  end

  def get_weaknesses_synthesis_table_data(weaknesses_count,
      weaknesses_count_by_risk, risk_levels)
    total_count = weaknesses_count_by_risk.sum(&:second)

    unless total_count == 0
      risk_level_values = risk_levels.map { |rl| rl[0] }.reverse
      statuses = Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).
        sort { |s1, s2| s1.last <=> s2.last }
      column_order = ['state', risk_level_values, 'count'].flatten
      column_data = []
      columns = {
        'state' => [Weakness.human_attribute_name('state'), 30],
        'count' => [Weakness.human_attribute_name('count'), 15]
      }

      risk_levels.each {|rl| columns[rl[0]] = [rl[0], (55 / risk_levels.size)]}

      statuses.each do |state|
        sub_total_count = weaknesses_count[state.last].inject(0) {|t, c| t + c[1]}
        percentage_total = 0
        column_row = {'state' => "<b>#{t("finding.status_#{state.first}")}</b>"}

        risk_levels.each do |rl|
          count = weaknesses_count[state.last][rl.last]
          percentage = sub_total_count > 0 ?
            (count * 100.0 / sub_total_count).round(2) : 0.0

          column_row[rl.first] = count > 0 ?
            "#{count} (#{'%.2f' % percentage}%)" : '-'
          percentage_total += percentage
        end

        column_row['count'] = sub_total_count > 0 ?
          "<b>#{sub_total_count} (#{'%.1f' % percentage_total}%)</b>" : '-'

        column_data << column_row
      end

      sub_total_count = weaknesses_count_by_risk.sum(&:second)

      column_row = {
        'state' => "<b>#{t(:'conclusion_committee_report.weaknesses_by_risk.total')}</b>",
        'count' => "<b>#{total_count}</b>"
      }

      weaknesses_count_by_risk.each do |risk, count|
        column_row[risk] = "<b>#{count}</b>"
      end

      column_data << column_row

      {:order => column_order, :data => column_data, :columns => columns}
    else
      t(:'follow_up_committee.without_weaknesses')
    end
  end

  def add_weaknesses_synthesis_table(pdf, data, font_size = PDF_FONT_SIZE)
    if data.kind_of?(Hash)
      columns = {}
      column_data = []

      data[:columns].each do |col_name, col_data|
        columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
          c.heading = col_data.first
          c.width = pdf.percent_width col_data.last
        end
      end

      data[:data].each do |row|
        new_row = {}

        row.each {|column, content| new_row[column] = content.to_iso}

        column_data << new_row
      end

      unless column_data.blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = column_data
          table.column_order = data[:order]
          table.split_rows = true
          table.font_size = font_size
          table.row_gap = (font_size * 0.5).round
          table.shade_rows = :none
          table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
          table.heading_font_size = font_size
          table.shade_headings = true
          table.bold_headings = true
          table.position = :left
          table.orientation = :right
          table.show_lines = :all
          table.render_on pdf
        end
      end
    else
      pdf.text "<i>#{data}</i>", :font_size => PDF_FONT_SIZE
    end
  end
end