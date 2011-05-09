module FollowUpCommonReports
  def weaknesses_by_state
    @title = t :'follow_up_committee.weaknesses_by_state_title'
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_state])
    @periods = periods_for_interval
    @audit_types = [
      [:internal, BusinessUnitType.internal_audit.map {|but| [but.name, but.id]}],
      [:external, BusinessUnitType.external_audit.map {|but| [but.name, but.id]}]
    ]
    @weaknesses_counts = {}
    @being_implemented_resumes = {}
    @status = Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).
      sort { |s1, s2| s1.last <=> s2.last }

    @periods.each do |period|
      @weaknesses_counts[period] ||= {}
      total_being_implemented_counts = {:current => 0, :stale => 0,
        :current_rescheduled => 0, :stale_rescheduled => 0}

      @audit_types.each do |audit_type|
        audit_type_symbol = audit_type.first

        audit_type.last.each do |audit_types|
          key = "#{audit_type_symbol}_#{audit_types.last}"
          conditions = {"#{BusinessUnitType.table_name}.id" => audit_types.last}
          @weaknesses_counts[period]['total_weaknesses'] ||= {}
          @weaknesses_counts[period]['total_oportunities'] ||= {}

          @weaknesses_counts[period]["#{key}_weaknesses"] =
            Weakness.with_status_for_report.list_all_by_date(
            @from_date, @to_date, false).send(
            :"#{audit_type_symbol}_audit").finals(false).for_period(
            period).where(conditions).group(:state).count
          @weaknesses_counts[period]["#{key}_oportunities"] =
            Oportunity.with_status_for_report.list_all_by_date(
            @from_date, @to_date, false).send(
            :"#{audit_type_symbol}_audit").finals(false).for_period(
            period).where(conditions).group(:state).count
          @weaknesses_counts[period]["#{key}_repeated"] =
            Finding.list_all_by_date(@from_date, @to_date, false).send(
            :"#{audit_type_symbol}_audit").finals(false).for_period(
            period).repeated.where(conditions).count
          being_implemented_counts = {:current => 0, :stale => 0,
            :current_rescheduled => 0, :stale_rescheduled => 0}

          @weaknesses_counts[period]["#{key}_weaknesses"].each do |state, count|
            @weaknesses_counts[period]['total_weaknesses'][state] ||= 0
            @weaknesses_counts[period]['total_weaknesses'][state] += count
          end

          @weaknesses_counts[period]["#{key}_oportunities"].each do |state, count|
            @weaknesses_counts[period]['total_oportunities'][state] ||= 0
            @weaknesses_counts[period]['total_oportunities'][state] += count
          end
          
          @weaknesses_counts[period]['total_repeated'] ||= 0
          @weaknesses_counts[period]['total_repeated'] +=
            @weaknesses_counts[period]["#{key}_repeated"]

          @status.each do |state|
            if state.first == :being_implemented
              being_implemented = Weakness.with_status_for_report.
                list_all_by_date(@from_date, @to_date, false).send(
                :"#{audit_type_symbol}_audit").finals(false).for_period(
                period).being_implemented.where(conditions)

              being_implemented.each do |w|
                unless w.stale?
                  unless w.rescheduled?
                    being_implemented_counts[:current] += 1
                  else
                    being_implemented_counts[:current_rescheduled] += 1
                  end
                else
                  unless w.rescheduled?
                    being_implemented_counts[:stale] += 1
                  else
                    being_implemented_counts[:stale_rescheduled] += 1
                  end
                end
              end
            end
          end

          @being_implemented_resumes[period] ||= {}
          @being_implemented_resumes[period][key] =
            being_implemented_resume_from_counts(being_implemented_counts)

          being_implemented_counts.each do |type, count|
            total_being_implemented_counts[type] += count
          end
        end
      end

      @being_implemented_resumes[period]['total'] =
        being_implemented_resume_from_counts(total_being_implemented_counts)
    end
  end

  def create_weaknesses_by_state
    self.weaknesses_by_state

    pdf = PDF::Writer.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE * 2

    pdf.add_description_item(
      t(:'follow_up_committee.period.title'),
      t(:'follow_up_committee.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :justify
      
      @audit_types.each do |audit_type|
        audit_type_symbol = audit_type.first

        pdf.move_pointer PDF_FONT_SIZE * 2

        pdf.add_title t(:"conclusion_committee_report.findings_type_#{audit_type_symbol}"),
          (PDF_FONT_SIZE * 1.25).round, :center

        audit_type.last.each do |audit_types|
          key = "#{audit_type_symbol}_#{audit_types.last}"

          pdf.move_pointer PDF_FONT_SIZE
          pdf.add_title audit_types.first, PDF_FONT_SIZE, :justify
          pdf.move_pointer PDF_FONT_SIZE

          weaknesses_count = @weaknesses_counts[period]["#{key}_weaknesses"]
          oportunities_count = @weaknesses_counts[period]["#{key}_oportunities"]
          repeated_count = @weaknesses_counts[period]["#{key}_repeated"]

          add_weaknesses_by_state_table(pdf, weaknesses_count,
            oportunities_count, repeated_count,
            @being_implemented_resumes[period][key], audit_type_symbol)
        end
      end

      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_title(
        t(:'follow_up_committee.weaknesses_by_state.period_summary',
          :period => period.inspect), (PDF_FONT_SIZE * 1.25).round, :center
      )
      pdf.move_pointer PDF_FONT_SIZE

      weaknesses_count = @weaknesses_counts[period]['total_weaknesses']
      oportunities_count = @weaknesses_counts[period]['total_oportunities']
      repeated_count = @weaknesses_counts[period]['total_repeated']

      add_weaknesses_by_state_table pdf, weaknesses_count, oportunities_count,
        repeated_count, @being_implemented_resumes[period]['total']
    end

    pdf.custom_save_as(
      t(:'follow_up_committee.weaknesses_by_state.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'weaknesses_by_state', 0)

    redirect_to PDF::Writer.relative_path(
      t(:'follow_up_committee.weaknesses_by_state.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'weaknesses_by_state', 0)
  end

  def weaknesses_by_risk
    @title = t :'follow_up_committee.weaknesses_by_risk_title'
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_risk])
    @periods = periods_for_interval
    @audit_types = [
      [:internal, BusinessUnitType.internal_audit.map {|but| [but.name, but.id]}],
      [:external, BusinessUnitType.external_audit.map {|but| [but.name, but.id]}]
    ]
    @tables_data = {}
    @repeated_counts = {}
    @being_implemented_resumes = {}
    @highest_being_implemented_resumes = {}
    risk_levels = parameter_in(@auth_organization.id,
      :admin_finding_risk_levels, @from_date)
    statuses = Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).
      sort { |s1, s2| s1.last <=> s2.last }
    highest_risk = risk_levels.sort {|r1, r2| r1[1] <=> r2[1]}.last

    @periods.each do |period|
      total_weaknesses_count = {}
      total_weaknesses_count_by_risk = {}
      total_repeated_count = 0
      total_being_implemented_counts = {:current => 0, :stale => 0,
        :current_rescheduled => 0, :stale_rescheduled => 0}
      total_highest_being_implemented_counts = {:current => 0, :stale => 0,
        :current_rescheduled => 0, :stale_rescheduled => 0}

      @audit_types.each do |audit_type|
        audit_type.last.each do |audit_types|
          weaknesses_count = {}
          weaknesses_count_by_risk = {}
          being_implemented_counts = {:current => 0, :stale => 0,
            :current_rescheduled => 0, :stale_rescheduled => 0}
          highest_being_implemented_counts = {:current => 0, :stale => 0,
            :current_rescheduled => 0, :stale_rescheduled => 0}
          audit_type_symbol = audit_type.kind_of?(Symbol) ?
            audit_type : audit_type.first
          key = "#{audit_type_symbol}_#{audit_types.last}"
          conditions = {"#{BusinessUnitType.table_name}.id" => audit_types.last}
          repeated_count = Finding.list_all_by_date(
            @from_date, @to_date, false).send(
            :"#{audit_type_symbol}_audit").finals(false).repeated.for_period(
            period).where(conditions).count

          risk_levels.each do |rl|
            weaknesses_count_by_risk[rl[0]] = 0
            total_weaknesses_count_by_risk[rl[0]] ||= 0

            statuses.each do |s|
              weaknesses_count[s[1]] ||= {}
              weaknesses_count[s[1]][rl[1]] =
                Weakness.with_status_for_report.list_all_by_date(
                @from_date, @to_date, false).send(
                :"#{audit_type_symbol}_audit").finals(false).for_period(
                period).where(
                {:state => s[1], :risk => rl[1]}.merge(conditions || {})
              ).count
              weaknesses_count_by_risk[rl[0]] += weaknesses_count[s[1]][rl[1]]
              total_weaknesses_count_by_risk[rl[0]] +=
                weaknesses_count[s[1]][rl[1]]

              total_weaknesses_count[s[1]] ||= {}
              total_weaknesses_count[s[1]][rl[1]] ||= 0
              total_weaknesses_count[s[1]][rl[1]] +=
                weaknesses_count[s[1]][rl[1]]

              if s.first == :being_implemented
                being_implemented = Weakness.with_status_for_report.
                  list_all_by_date(@from_date, @to_date, false).send(
                  :"#{audit_type_symbol}_audit").finals(false).for_period(
                  period).being_implemented.where(
                  {:risk => rl[1]}.merge(conditions || {})
                )

                being_implemented.each do |f|
                  unless f.stale?
                    unless f.respond_to?(:rescheduled?) && f.rescheduled?
                      being_implemented_counts[:current] += 1

                      if rl == highest_risk
                        highest_being_implemented_counts[:current] += 1
                      end
                    else
                      being_implemented_counts[:current_rescheduled] += 1

                      if rl == highest_risk
                        highest_being_implemented_counts[:current_rescheduled] +=1
                      end
                    end
                  else
                    unless f.respond_to?(:rescheduled?) && f.rescheduled?
                      being_implemented_counts[:stale] += 1

                      if rl == highest_risk
                        highest_being_implemented_counts[:stale] += 1
                      end
                    else
                      being_implemented_counts[:stale_rescheduled] += 1

                      if rl == highest_risk
                        highest_being_implemented_counts[:stale_rescheduled] += 1
                      end
                    end
                  end
                end
              end
            end
          end

          being_implemented_counts.each do |type, count|
            total_being_implemented_counts[type] += count
          end

          highest_being_implemented_counts.each do |type, count|
            total_highest_being_implemented_counts[type] += count
          end

          total_repeated_count += repeated_count

          @repeated_counts[period] ||= {}
          @repeated_counts[period][key] = repeated_count
          @being_implemented_resumes[period] ||= {}
          @being_implemented_resumes[period][key] =
            being_implemented_resume_from_counts(being_implemented_counts)
          @highest_being_implemented_resumes[period] ||= {}
          @highest_being_implemented_resumes[period][key] =
            being_implemented_resume_from_counts(highest_being_implemented_counts)
          @tables_data[period] ||= {}
          @tables_data[period][key] = get_weaknesses_synthesis_table_data(
            weaknesses_count, weaknesses_count_by_risk, risk_levels)
        end
      end

      @repeated_counts[period]['total'] = total_repeated_count
      @being_implemented_resumes[period]['total'] =
        being_implemented_resume_from_counts(total_being_implemented_counts)
      @highest_being_implemented_resumes[period]['total'] =
        being_implemented_resume_from_counts(
          total_highest_being_implemented_counts)
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
      t(:'follow_up_committee.period.title'),
      t(:'follow_up_committee.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :justify

      @audit_types.each do |audit_type|
        audit_type_symbol = audit_type.kind_of?(Symbol) ?
          audit_type : audit_type.first

        pdf.move_pointer PDF_FONT_SIZE * 2

        pdf.add_title t(:"conclusion_committee_report.weaknesses_type_#{audit_type_symbol}"),
          (PDF_FONT_SIZE * 1.25).round, :center

        audit_type.last.each do |audit_types|
          key = "#{audit_type_symbol}_#{audit_types.last}"

          pdf.move_pointer PDF_FONT_SIZE
          pdf.add_title audit_types.first, PDF_FONT_SIZE, :justify
          pdf.move_pointer PDF_FONT_SIZE

          add_weaknesses_synthesis_table(pdf, @tables_data[period][key])

          add_being_implemented_resume(pdf,
            @being_implemented_resumes[period][key])
          add_being_implemented_resume(pdf,
            @highest_being_implemented_resumes[period][key], 2)

          if @repeated_counts[period][key] > 0
            pdf.move_pointer((PDF_FONT_SIZE * 0.5).round)
            pdf.text t(:'follow_up_committee.repeated_count',
              :count => @repeated_counts[period][key],
              :font_size => PDF_FONT_SIZE)
          end
        end
      end

      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_title(
        t(:'follow_up_committee.weaknesses_by_risk.period_summary',
          :period => period.inspect), (PDF_FONT_SIZE * 1.25).round, :center
      )
      pdf.move_pointer PDF_FONT_SIZE

      add_weaknesses_synthesis_table(pdf, @tables_data[period]['total'])

      add_being_implemented_resume(pdf,
        @being_implemented_resumes[period]['total'])
      add_being_implemented_resume(pdf,
        @highest_being_implemented_resumes[period]['total'], 2)

      if @repeated_counts[period]['total'] > 0
        pdf.move_pointer((PDF_FONT_SIZE * 0.5).round)
        pdf.text t(:'follow_up_committee.repeated_count',
          :count => @repeated_counts[period]['total'],
          :font_size => PDF_FONT_SIZE)
      end
    end

    pdf.custom_save_as(
      t(:'follow_up_committee.weaknesses_by_risk.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'weaknesses_by_risk', 0)

    redirect_to PDF::Writer.relative_path(
      t(:'follow_up_committee.weaknesses_by_risk.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'weaknesses_by_risk', 0)
  end
  
  def weaknesses_by_audit_type
    @title = t :'follow_up_committee.weaknesses_by_audit_type_title'
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_audit_type])
    @periods = periods_for_interval
    @audit_types = [:internal, :external]
    @data = {}
    risk_levels = parameter_in(@auth_organization.id,
      :admin_finding_risk_levels, @from_date)
    statuses = Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).
      sort { |s1, s2| s1.last <=> s2.last }
    highest_risk = risk_levels.sort {|r1, r2| r1[1] <=> r2[1]}.last

    @periods.each do |period|
      @data[period] ||= {}

      @audit_types.each do |audit_type|
        @data[period][audit_type] = []
        conclusion_final_review = ConclusionFinalReview.list_all_by_date(
          @from_date, @to_date).send(:"#{audit_type}_audit").for_period(period)
        reviews_by_audit_type = {}

        conclusion_final_review.each do |cfr|
          business_unit = cfr.review.plan_item.business_unit
          business_unit_type = business_unit.business_unit_type.name

          reviews_by_audit_type[business_unit_type] ||= {}
          reviews_by_audit_type[business_unit_type][business_unit.name] ||= []
          reviews_by_audit_type[business_unit_type][business_unit.name] << cfr
        end

        reviews_by_audit_type.each do |bu_type, bu_data|
          title = "#{Review.human_attribute_name(:audit_type)}: #{bu_type}"
          business_units = {}

          bu_data.values.each do |cfrs|
            unless cfrs.empty?
              business_unit = cfrs.first.plan_item.business_unit
              weaknesses = []
              oportunities = []
              repeated_count = 0

              cfrs.sort! {|cfr1, cfr2| cfr1.review.score <=> cfr2.review.score}

              cfrs.each do |cfr|
                review = cfr.review
                weaknesses |= review.weaknesses
                oportunities |= review.oportunities
                repeated_count += review.weaknesses.repeated.count +
                  review.oportunities.repeated.count
              end

              grouped_weaknesses = weaknesses.group_by(&:state)
              grouped_oportunities = oportunities.group_by(&:state)
              oportunities_table_data = []
              weaknesses_count = {}
              weaknesses_count_by_risk = {}
              total_oportunities = grouped_oportunities.values.sum(&:size)
              being_implemented_counts = {:current => 0, :stale => 0,
                :current_rescheduled => 0, :stale_rescheduled => 0}
              highest_being_implemented_counts = {:current => 0, :stale => 0,
                :current_rescheduled => 0, :stale_rescheduled => 0}

              if total_oportunities > 0
                statuses.each do |s|
                  o_count = (grouped_oportunities[s[1]] || []).size
                  oportunities_percentage = total_oportunities > 0 ?
                    o_count.to_f / total_oportunities * 100 : 0.0

                  oportunities_table_data << {
                    'state' => "<b>#{t(:"finding.status_#{s[0]}")}</b>".to_iso,
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

                  if s.first == :being_implemented
                    being_implemented = weaknesses_for_status.select do |w|
                      w.risk == rl[1]
                    end

                    being_implemented.each do |w|
                      unless w.stale?
                        unless w.rescheduled?
                          being_implemented_counts[:current] += 1

                          if rl == highest_risk
                            highest_being_implemented_counts[:current] += 1
                          end
                        else
                          being_implemented_counts[:current_rescheduled] += 1

                          if rl == highest_risk
                            highest_being_implemented_counts[:current_rescheduled] += 1
                          end
                        end
                      else
                        unless w.rescheduled?
                          being_implemented_counts[:stale] += 1

                          if rl == highest_risk
                            highest_being_implemented_counts[:stale] += 1
                          end
                        else
                          being_implemented_counts[:stale_rescheduled] += 1

                          if rl == highest_risk
                            highest_being_implemented_counts[:stale_rescheduled] += 1
                          end
                        end
                      end
                    end
                  end
                end
              end

              weaknesses_table_data = get_weaknesses_synthesis_table_data(
                weaknesses_count, weaknesses_count_by_risk, risk_levels)
              being_implemented_resume = being_implemented_resume_from_counts(
                being_implemented_counts)
              highest_being_implemented_resume =
                being_implemented_resume_from_counts(
                highest_being_implemented_counts)

              business_units[business_unit] = {
                :conclusion_reviews => cfrs,
                :repeated_count => repeated_count,
                :weaknesses_table_data => weaknesses_table_data,
                :oportunities_table_data => oportunities_table_data,
                :being_implemented_resume => being_implemented_resume,
                :highest_being_implemented_resume =>
                  highest_being_implemented_resume
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
      t(:'follow_up_committee.period.title'),
      t(:'follow_up_committee.period.range',
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

              pdf.text "<b>#{t(:'actioncontroller.reviews')}</b>"
              pdf.move_pointer PDF_FONT_SIZE

              bu_data[:conclusion_reviews].each do |cr|
                findings_count = cr.review.weaknesses.size +
                  cr.review.oportunities.size

                text = "<C:bullet /> <b>#{cr.review}</b>: " +
                  cr.review.reload.score_text

                if findings_count == 0
                  text << " (#{t(:'follow_up_committee.weaknesses_by_audit_type.without_weaknesses')})"
                end

                pdf.text text, :left => PDF_FONT_SIZE * 2
              end

              pdf.move_pointer PDF_FONT_SIZE

              pdf.add_title(
                t(:'follow_up_committee.weaknesses_by_audit_type.weaknesses'),
                PDF_FONT_SIZE)

              pdf.move_pointer PDF_FONT_SIZE

              add_weaknesses_synthesis_table(pdf,
                bu_data[:weaknesses_table_data], 10)
              add_being_implemented_resume(pdf,
                bu_data[:being_implemented_resume])
              add_being_implemented_resume(pdf,
                bu_data[:highest_being_implemented_resume], 2)

              if type == :internal
                pdf.move_pointer PDF_FONT_SIZE

                pdf.add_title(
                  t(:'follow_up_committee.weaknesses_by_audit_type.oportunities'),
                  PDF_FONT_SIZE)

                pdf.move_pointer PDF_FONT_SIZE

                unless bu_data[:oportunities_table_data].blank?
                  columns = {
                    'state' => [Oportunity.human_attribute_name(:state), 30],
                    'count' => [Oportunity.human_attribute_name(:count), 70]
                  }

                  columns.each do |col_name, col_data|
                    columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |column|
                      column.heading = col_data.first
                      column.width = pdf.percent_width col_data.last
                    end
                  end

                  unless bu_data[:oportunities_table_data].blank?
                    PDF::SimpleTable.new do |table|
                      table.width = pdf.page_usable_width
                      table.columns = columns
                      table.data = bu_data[:oportunities_table_data]
                      table.column_order = ['state', 'count']
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
                  pdf.text t(:'follow_up_committee.without_oportunities')
                end
              end

              if bu_data[:repeated_count] > 0
                pdf.move_pointer((PDF_FONT_SIZE * 0.5).round)
                pdf.text t(:'follow_up_committee.repeated_count',
                  :count => bu_data[:repeated_count],
                  :font_size => PDF_FONT_SIZE)
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
      t(:'follow_up_committee.weaknesses_by_audit_type.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'weaknesses_by_audit_type',
      0)

    redirect_to PDF::Writer.relative_path(
      t(:'follow_up_committee.weaknesses_by_audit_type.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'weaknesses_by_audit_type',
      0)
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

  # Devuelve el ID de la organización seleccionada, sólo si el usuario está
  # autorizado para verla. Caso contrario retorna la organización con la que
  # está autenticado el usuario.
  def get_organization #:doc:
    auth_organizations = @auth_user.organizations.map { |o| o.id }
    params[:organization] && auth_organizations.include?(
      params[:organization].to_i) ?
      params[:organization] : @auth_organization.id
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
        sub_total_count = weaknesses_count[state.last].sum(&:second)
        percentage_total = 0
        column_row = {'state' => "<b>#{t("finding.status_#{state.first}")}</b>"}

        risk_levels.each do |rl|
          highest_risk = risk_levels.sort {|r1, r2| r1[1] <=> r2[1]}.last
          count = weaknesses_count[state.last][rl.last]
          percentage = sub_total_count > 0 ?
            (count * 100.0 / sub_total_count).round(2) : 0.0

          column_row[rl.first] = count > 0 ?
            "#{count} (#{'%.2f' % percentage}%)" : '-'
          percentage_total += percentage
          
          if count > 0 && rl == highest_risk && state[0] == :being_implemented
            column_row[rl.first] << '**'
          end
        end

        column_row['count'] = sub_total_count > 0 ?
          "<b>#{sub_total_count} (#{'%.1f' % percentage_total}%)</b>" : '-'

        if state.first == :being_implemented && sub_total_count != 0
          column_row['count'] << '*'
        end

        column_data << column_row
      end

      column_row = {
        'state' => "<b>#{t(:'follow_up_committee.weaknesses_by_risk.total')}</b>",
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
      repeated_count, being_implemented_resume, audit_type_symbol = :internal)
    total_weaknesses = weaknesses_count.values.sum
    total_oportunities = oportunities_count.values.sum

    if (total_weaknesses + total_oportunities + repeated_count) > 0
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
          'state' => "<b>#{t("finding.status_#{state.first}")}</b>".to_iso,
          'weaknesses_count' =>
            "#{w_count} (#{'%.2f' % weaknesses_percentage.round(2)}%)",
          'oportunities_count' =>
            "#{o_count} (#{'%.2f' % oportunities_percentage.round(2)}%)",
        }

        if state.first == :being_implemented
          if column_data.last['weaknesses_count'] != '0'
            column_data.last['weaknesses_count'] << ' *'
          end
        end
      end

      column_data << {
        'state' =>
          "<b>#{t(:'follow_up_committee.weaknesses_by_state.total')}</b>".to_iso,
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

      add_being_implemented_resume(pdf, being_implemented_resume)

      if repeated_count > 0
        pdf.move_pointer((PDF_FONT_SIZE * 0.5).round)
        pdf.text t(:'follow_up_committee.repeated_count',
          :count => repeated_count, :font_size => PDF_FONT_SIZE)
      end
    else
      pdf.text t(:'follow_up_committee.without_weaknesses'),
        :font_size => PDF_FONT_SIZE
    end
  end

  def add_being_implemented_resume(pdf, being_implemented_resume = nil,
      asterisks = 1)
    unless being_implemented_resume.blank?
      pdf.move_pointer PDF_FONT_SIZE if asterisks == 1

      pdf.text(('*' * asterisks) + " #{being_implemented_resume}",
        :font_size => PDF_FONT_SIZE)
    end
  end

  def being_implemented_resume_from_counts(being_implemented_counts = {})
    being_implemented_resume = []
    total_of_being_implemented = being_implemented_counts.values.sum
    sub_statuses = [:current, :current_rescheduled, :stale, :stale_rescheduled]

    sub_statuses.each do |sub_status|
      count = being_implemented_counts[sub_status]
      sub_status_percentage = count == 0 ?
        0.00 : (count.to_f / total_of_being_implemented) * 100
      sub_status_resume = "<b>#{count}</b> "
      sub_status_resume << t(
        "follow_up_committee.weaknesses_being_implemented_#{sub_status}",
        :count => count)
      sub_status_resume << " (#{'%.2f' % sub_status_percentage}%)"

      being_implemented_resume << sub_status_resume
    end

    unless being_implemented_resume.blank? || total_of_being_implemented == 0
      being_implemented_resume.to_sentence
    end
  end
end