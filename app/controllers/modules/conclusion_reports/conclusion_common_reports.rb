module ConclusionCommonReports
  def weaknesses_by_state
    @title = t('conclusion_committee_report.weaknesses_by_state_title')
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_state])
    @periods = periods_for_interval
    @audit_types = [
      [:internal, BusinessUnitType.internal_audit.map {|but| [but.name, but.id]}],
      [:external, BusinessUnitType.external_audit.map {|but| [but.name, but.id]}]
    ]
    @weaknesses_counts = {}
    @status = Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).
        sort { |s1, s2| s1.last <=> s2.last }

    @periods.each do |period|
      @weaknesses_counts[period] ||= {}

      @audit_types.each do |audit_type|
        audit_type_symbol = audit_type.first
        
        unless audit_type.last.empty?
          audit_type.last.each do |audit_types|
            key = "#{audit_type_symbol}_#{audit_types.last}"
            conditions = {"#{BusinessUnitType.table_name}.id" => audit_types.last}
            @weaknesses_counts[period]['total_weaknesses'] ||= {}
            @weaknesses_counts[period]['total_oportunities'] ||= {}

            @weaknesses_counts[period]["#{key}_weaknesses"] =
              Weakness.list_all_by_date(@from_date, @to_date, false).
                with_status_for_report.send("#{audit_type_symbol}_audit").
                for_period(period).finals(true).where(conditions).group(
                :state).count
            @weaknesses_counts[period]["#{key}_oportunities"] =
              Oportunity.list_all_by_date(@from_date, @to_date, false).
              with_status_for_report.send("#{audit_type_symbol}_audit").
              for_period(period).finals(true).where(conditions).group(
              :state).count

            @weaknesses_counts[period]["#{key}_weaknesses"].each do |state, count|
              @weaknesses_counts[period]['total_weaknesses'][state] ||= 0
              @weaknesses_counts[period]['total_weaknesses'][state] += count
            end

            @weaknesses_counts[period]["#{key}_oportunities"].each do |state, count|
              @weaknesses_counts[period]['total_oportunities'][state] ||= 0
              @weaknesses_counts[period]['total_oportunities'][state] += count
            end
          end
        end
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
      t('conclusion_committee_report.period.title'),
      t('conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :justify

      @audit_types.each do |audit_type|
        audit_type_symbol = audit_type.first
        
        unless audit_type.last.empty?
          pdf.move_pointer PDF_FONT_SIZE * 2

          pdf.add_title t("conclusion_committee_report.findings_type_#{audit_type_symbol}"),
            (PDF_FONT_SIZE * 1.25).round, :center

          audit_type.last.each do |audit_types|
            key = "#{audit_type_symbol}_#{audit_types.last}"

            pdf.move_pointer PDF_FONT_SIZE
            pdf.add_title audit_types.first, PDF_FONT_SIZE, :justify
            pdf.move_pointer PDF_FONT_SIZE

            weaknesses_count = @weaknesses_counts[period]["#{key}_weaknesses"]
            oportunities_count = @weaknesses_counts[period]["#{key}_oportunities"]

            add_weaknesses_by_state_table pdf, weaknesses_count,
              oportunities_count, audit_type_symbol
          end
        end
      end

      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_title(
        t('conclusion_committee_report.weaknesses_by_state.period_summary',
          :period => period.inspect), (PDF_FONT_SIZE * 1.25).round, :center
      )
      pdf.move_pointer PDF_FONT_SIZE

      weaknesses_count = @weaknesses_counts[period]['total_weaknesses']
      oportunities_count = @weaknesses_counts[period]['total_oportunities']

      add_weaknesses_by_state_table pdf, weaknesses_count, oportunities_count
    end

    pdf.custom_save_as(
      t('conclusion_committee_report.weaknesses_by_state.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)),
      'conclusion_weaknesses_by_state', 0)

    redirect_to PDF::Writer.relative_path(
      t('conclusion_committee_report.weaknesses_by_state.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)),
      'conclusion_weaknesses_by_state', 0)
  end

  def weaknesses_by_risk
    @title = t('conclusion_committee_report.weaknesses_by_risk_title')
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_risk])
    @periods = periods_for_interval
    @audit_types = [
      [:internal, BusinessUnitType.internal_audit.map {|but| [but.name, but.id]}],
      [:external, BusinessUnitType.external_audit.map {|but| [but.name, but.id]}]
    ]
    @tables_data = {}
    risk_levels = parameter_in(@auth_organization.id,
      :admin_finding_risk_levels, @from_date)
    statuses = Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).
      sort { |s1, s2| s1.last <=> s2.last }

    @periods.each do |period|
      total_weaknesses_count = {}
      total_weaknesses_count_by_risk = {}

      @audit_types.each do |audit_type|
        weaknesses_count = {}
        weaknesses_count_by_risk = {}
        audit_type_symbol = audit_type.first
        
        unless audit_type.last.empty?
          audit_type.last.each do |audit_types|
            key = "#{audit_type_symbol}_#{audit_types.last}"
            conditions = {"#{BusinessUnitType.table_name}.id" => audit_types.last}

            risk_levels.each do |rl|
              weaknesses_count_by_risk[rl[0]] = 0
              total_weaknesses_count_by_risk[rl[0]] ||= 0

              statuses.each do |s|
                weaknesses_count[s[1]] ||= {}
                weaknesses_count[s[1]][rl[1]] = Weakness.list_all_by_date(
                  @from_date, @to_date, false).with_status_for_report.send(
                  "#{audit_type_symbol}_audit").for_period(period).finals(
                  true).where(
                    {:state => s[1], :risk => rl[1]}.merge(conditions || {})
                  ).count
                weaknesses_count_by_risk[rl[0]] += weaknesses_count[s[1]][rl[1]]
                total_weaknesses_count_by_risk[rl[0]] +=
                  weaknesses_count[s[1]][rl[1]]

                total_weaknesses_count[s[1]] ||= {}
                total_weaknesses_count[s[1]][rl[1]] ||= 0
                total_weaknesses_count[s[1]][rl[1]] +=
                  weaknesses_count[s[1]][rl[1]]
              end
            end

            @tables_data[period] ||= {}
            @tables_data[period][key] = get_weaknesses_synthesis_table_data(
              weaknesses_count, weaknesses_count_by_risk, risk_levels)
          end
        end
      end

      @tables_data[period]['total'] = get_weaknesses_synthesis_table_data(
        total_weaknesses_count, total_weaknesses_count_by_risk, risk_levels)
    end
  end

  def create_weaknesses_by_risk
    self.weaknesses_by_risk

    pdf = PDF::Writer.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE * 2

    pdf.add_description_item(
      t('conclusion_committee_report.period.title'),
      t('conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :justify
      
      @audit_types.each do |audit_type|
        audit_type_symbol = audit_type.kind_of?(Symbol) ?
          audit_type : audit_type.first
        
        unless audit_type.last.empty?

          pdf.move_pointer PDF_FONT_SIZE * 2

          pdf.add_title t("conclusion_committee_report.weaknesses_type_#{audit_type_symbol}"),
            (PDF_FONT_SIZE * 1.25).round, :center

          audit_type.last.each do |audit_types|
            key = "#{audit_type_symbol}_#{audit_types.last}"

            pdf.move_pointer PDF_FONT_SIZE
            pdf.add_title audit_types.first, PDF_FONT_SIZE, :justify
            pdf.move_pointer PDF_FONT_SIZE

            add_weaknesses_synthesis_table(pdf, @tables_data[period][key])
          end
        end
      end

      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_title(
        t('conclusion_committee_report.weaknesses_by_risk.period_summary',
          :period => period.inspect), (PDF_FONT_SIZE * 1.25).round, :center
      )
      pdf.move_pointer PDF_FONT_SIZE

      add_weaknesses_synthesis_table(pdf, @tables_data[period]['total'])
    end

    pdf.custom_save_as(
      t('conclusion_committee_report.weaknesses_by_risk.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)),
      'conclusion_weaknesses_by_risk', 0)

    redirect_to PDF::Writer.relative_path(
      t('conclusion_committee_report.weaknesses_by_risk.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)),
      'conclusion_weaknesses_by_risk', 0)
  end

  def weaknesses_by_audit_type
    @title = t('conclusion_committee_report.weaknesses_by_audit_type_title')
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

              cfrs.sort! {|cfr1, cfr2| cfr1.review.score <=> cfr2.review.score}

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
                    "<b>#{t('conclusion_committee_report.weaknesses_by_audit_type.total')}</b>".to_iso,
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
      t('conclusion_committee_report.period.title'),
      t('conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
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

              pdf.text "<b>#{t('actioncontroller.reviews')}</b>"
              pdf.move_pointer PDF_FONT_SIZE

              bu_data[:conclusion_reviews].each do |cr|
                findings_count = cr.review.final_weaknesses.size +
                  cr.review.final_oportunities.size

                text = "<C:bullet /> <b>#{cr.review}</b>: " +
                  cr.review.reload.score_text

                if findings_count == 0
                  text << " (#{t('conclusion_committee_report.weaknesses_by_audit_type.without_weaknesses')})"
                end

                pdf.text text, :left => PDF_FONT_SIZE * 2
              end

              pdf.move_pointer PDF_FONT_SIZE

              pdf.add_title(
                t('conclusion_committee_report.weaknesses_by_audit_type.weaknesses'),
                PDF_FONT_SIZE)

              pdf.move_pointer PDF_FONT_SIZE

              add_weaknesses_synthesis_table(pdf,
                bu_data[:weaknesses_table_data], 10)

              if type == :internal
                pdf.move_pointer PDF_FONT_SIZE

                pdf.add_title(
                  t('conclusion_committee_report.weaknesses_by_audit_type.oportunities'),
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
                  pdf.text t('follow_up_committee.without_oportunities')
                end
              end
            end
          end
        else
          pdf.text t('follow_up_committee.without_weaknesses'),
            :font_size => PDF_FONT_SIZE
        end
      end
    end

    pdf.custom_save_as(
      t('conclusion_committee_report.weaknesses_by_audit_type.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)),
      'conclusion_weaknesses_by_audit_type', 0)

    redirect_to PDF::Writer.relative_path(
      t('conclusion_committee_report.weaknesses_by_audit_type.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)),
      'conclusion_weaknesses_by_audit_type', 0)
  end
  
  def control_objective_stats
    @title = t('conclusion_committee_report.control_objective_stats_title')
    @from_date, @to_date = *make_date_range(params[:control_objective_stats])
    @periods = periods_for_interval
    @risk_levels = []
    @filters = []
    @columns = [
      ['process_control', BestPractice.human_attribute_name(:process_controls), 20],
      ['control_objective', ControlObjective.model_name.human, 40],
      ['effectiveness', t('conclusion_committee_report.control_objective_stats.average_effectiveness'), 20],
      ['weaknesses_count', t('review.weaknesses_count'), 20]
    ]
    conclusion_reviews = ConclusionFinalReview.list_all_by_date(
      @from_date, @to_date
    )
    @process_control_data = {}
    @control_objectives_data = {}
    @reviews_score_data = {}
    reviews_score_data = {}
    
    if params[:control_objective_stats]
      unless params[:control_objective_stats][:business_unit_type].blank?
        @selected_business_unit = BusinessUnitType.find(
          params[:control_objective_stats][:business_unit_type])
        conclusion_reviews = conclusion_reviews.by_business_unit_type(
          @selected_business_unit.id)
        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = " +
          "\"#{@selected_business_unit.name.strip}\""
      end

      unless params[:control_objective_stats][:business_unit].blank?
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
    end
    
    @periods.each do |period|
      reviews_score_data[period] ||= []
      process_controls = {}
      
      conclusion_reviews.for_period(period).each do |c_r|
        c_r.review.control_objective_items_for_score.each do |coi|
          process_controls[coi.process_control.name] ||= {}
          coi_data = process_controls[coi.process_control.name][coi.control_objective] || {}
          coi_data[:weaknesses_ids] ||= {}
          weaknesses_count = {}
          
          coi.final_weaknesses.each do |w|
            @risk_levels |= parameter_in(
              @auth_organization.id,
              :admin_finding_risk_levels, w.created_at
            ).sort {|r1, r2| r2[1] <=> r1[1]}.map { |r| r.first }
            
            weaknesses_count[w.risk_text] ||= 0
            weaknesses_count[w.risk_text] += 1
            coi_data[:weaknesses_ids][w.risk_text] ||= []
            coi_data[:weaknesses_ids][w.risk_text] << w.id
          end
          
          coi_data[:weaknesses] ||= {}
          coi_data[:effectiveness] ||= []
          coi_data[:effectiveness] << coi.effectiveness
          
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
        cos.each do |co, coi_data|
          @control_objectives_data[co.name] ||= {}
          reviews_count = coi_data[:effectiveness].size
          effectiveness = reviews_count > 0 ?
            coi_data[:effectiveness].sum / reviews_count : 100
          weaknesses_count = coi_data[:weaknesses]
          
          if weaknesses_count.values.sum == 0
            weaknesses_count_text = t(
              'conclusion_committee_report.control_objective_stats.without_weaknesses'
            )
          else
            weaknesses_count_text = []
            
            @risk_levels.each do |risk|
              text = "#{risk}: #{weaknesses_count[risk] || 0}"
              
              @control_objectives_data[co.name][text] = coi_data[:weaknesses_ids][risk]
              
              weaknesses_count_text << text
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
    end
  end
  
  def create_control_objective_stats
    self.control_objective_stats

    pdf = PDF::Writer.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE

    pdf.add_description_item(
      t('conclusion_committee_report.period.title'),
      t('conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :justify

      pdf.move_pointer PDF_FONT_SIZE
      
      column_data = []
      columns = {}

      @columns.each do |col_name, col_title, col_width|
        columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |column|
          column.heading = col_title
          column.width = pdf.percent_width col_width
        end
      end

      @process_control_data[period].each do |row|
        new_row = {}

        row.each do |column_name, column_content|
          new_row[column_name] = column_content.kind_of?(Array) ?
            column_content.map {|l| "  <C:bullet /> #{l}"}.join("\n").to_iso :
            column_content.to_iso
        end

        column_data << new_row
      end

      unless column_data.blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = column_data
          table.column_order = @columns.map(&:first)
          table.split_rows = true
          table.row_gap = PDF_FONT_SIZE
          table.font_size = (PDF_FONT_SIZE * 0.75).round
          table.shade_color = Color::RGB.from_percentage(95, 95, 95)
          table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
          table.heading_font_size = PDF_FONT_SIZE
          table.shade_headings = true
          table.position = :left
          table.orientation = :right
          table.render_on pdf
        end
      else
        pdf.text(
          t('conclusion_committee_report.control_objective_stats.without_audits_in_the_period'))
      end
      
      pdf.move_pointer PDF_FONT_SIZE
      pdf.text t(
        'conclusion_committee_report.control_objective_stats.review_score_average',
        :score => @reviews_score_data[period]
      )
    end

    unless @filters.empty?
      pdf.move_pointer PDF_FONT_SIZE
      pdf.text t('conclusion_committee_report.applied_filters',
        :filters => @filters.to_sentence, :count => @filters.size),
        :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full
    end

    pdf.custom_save_as(
      t('conclusion_committee_report.control_objective_stats.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'control_objective_stats', 0)

    redirect_to PDF::Writer.relative_path(
      t('conclusion_committee_report.control_objective_stats.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'control_objective_stats', 0)
  end
  
  def process_control_stats
    @title = t('conclusion_committee_report.process_control_stats_title')
    @from_date, @to_date = *make_date_range(params[:process_control_stats])
    @periods = periods_for_interval
    @risk_levels = []
    @filters = []
    @columns = [
      ['process_control', BestPractice.human_attribute_name(:process_controls), 60],
      ['effectiveness', t('conclusion_committee_report.process_control_stats.average_effectiveness'), 20],
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
        c_r.review.control_objective_items_for_score.each do |coi|
          pc_data = process_controls[coi.process_control.name] ||= {}
          pc_data[:weaknesses_ids] ||= {}
          pc_data[:reviews] ||= 0
          weaknesses_count = {}
          
          coi.final_weaknesses.each do |w|
            @risk_levels |= parameter_in(
              @auth_organization.id,
              :admin_finding_risk_levels, w.created_at
            ).sort { |r1, r2| r2[1] <=> r1[1] }.map { |r| r.first }
            
            weaknesses_count[w.risk_text] ||= 0
            weaknesses_count[w.risk_text] += 1
            pc_data[:weaknesses_ids][w.risk_text] ||= []
            pc_data[:weaknesses_ids][w.risk_text] << w.id
          end
          
          pc_data[:reviews] += 1 if coi.final_weaknesses.size > 0
          
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
            'conclusion_committee_report.process_control_stats.without_weaknesses'
          )
        else
          weaknesses_count_text = []
            
          @risk_levels.each do |risk|
            text = "#{risk}: #{weaknesses_count[risk] || 0}"

            @process_control_ids_data[pc][text] = pc_data[:weaknesses_ids][risk]

            weaknesses_count_text << text
          end
        end
        
        weaknesses_count_text = weaknesses_count.values.sum == 0 ?
          t('conclusion_committee_report.process_control_stats.without_weaknesses') :
          @risk_levels.map { |risk| "#{risk}: #{weaknesses_count[risk] || 0}"}

        @process_control_data[period] << {
          'process_control' => pc,
          'effectiveness' => t(
            'conclusion_committee_report.process_control_stats.average_effectiveness_resume',
            :effectiveness => "#{'%.2f' % effectiveness}%",
            :count => pc_data[:reviews]
          ),
          'weaknesses_count' => weaknesses_count_text
        }
      end
    end
  end
  
  def create_process_control_stats
    self.process_control_stats

    pdf = PDF::Writer.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE

    pdf.add_description_item(
      t('conclusion_committee_report.period.title'),
      t('conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :justify

      pdf.move_pointer PDF_FONT_SIZE
      
      column_data = []
      columns = {}

      @columns.each do |col_name, col_title, col_width|
        columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |column|
          column.heading = col_title
          column.width = pdf.percent_width col_width
        end
      end

      @process_control_data[period].each do |row|
        new_row = {}

        row.each do |column_name, column_content|
          new_row[column_name] = column_content.kind_of?(Array) ?
            column_content.map {|l| "  <C:bullet /> #{l}"}.join("\n").to_iso :
            column_content.to_iso
        end

        column_data << new_row
      end

      unless column_data.blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = column_data
          table.column_order = @columns.map(&:first)
          table.split_rows = true
          table.row_gap = PDF_FONT_SIZE
          table.font_size = (PDF_FONT_SIZE * 0.75).round
          table.shade_color = Color::RGB.from_percentage(95, 95, 95)
          table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
          table.heading_font_size = PDF_FONT_SIZE
          table.shade_headings = true
          table.position = :left
          table.orientation = :right
          table.render_on pdf
        end
      else
        pdf.text(
          t('conclusion_committee_report.process_control_stats.without_audits_in_the_period'))
      end
      
      pdf.move_pointer PDF_FONT_SIZE
      pdf.text t(
        'conclusion_committee_report.control_objective_stats.review_score_average',
        :score => @reviews_score_data[period]
      )
    end

    unless @filters.empty?
      pdf.move_pointer PDF_FONT_SIZE
      pdf.text t('conclusion_committee_report.applied_filters',
        :filters => @filters.to_sentence, :count => @filters.size),
        :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full
    end

    pdf.custom_save_as(
      t('conclusion_committee_report.process_control_stats.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'process_control_stats', 0)

    redirect_to PDF::Writer.relative_path(
      t('conclusion_committee_report.process_control_stats.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'process_control_stats', 0)
  end

  private

  def periods_for_interval
    Period.includes(:reviews => :conclusion_final_review).where(
      [
        "#{ConclusionFinalReview.table_name}.issue_date BETWEEN :from_date AND :to_date",
        "#{Period.table_name}.organization_id = :organization_id"
      ].join(' AND '),
      {
        :from_date => @from_date,
        :to_date => @to_date,
        :organization_id => @auth_organization.id
      }
    )
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

  def add_weaknesses_by_state_table(pdf, weaknesses_count, oportunities_count,
      audit_type_symbol = :internal)
    total_weaknesses = weaknesses_count.values.sum
    total_oportunities = oportunities_count.values.sum

    if (total_weaknesses + total_oportunities) > 0
      columns = {
        'state' => [Finding.human_attribute_name(:state), 30],
        'weaknesses_count' => [
          t(:'conclusion_committee_report.weaknesses_by_state.weaknesses_column'),
          audit_type_symbol == :internal ? 35 : 70]
      }
      column_data = []

      if audit_type_symbol == :internal
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
          table.column_order = audit_type_symbol == :internal ?
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