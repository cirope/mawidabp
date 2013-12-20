module Reports::WeaknessesByRisk
  include Reports::Pdf
  include Reports::Period
  include Parameters::Risk

  def weaknesses_by_risk
    @controller = params[:controller_name]
    final = params[:final]
    @title = t("#{@controller}_committee_report.weaknesses_by_risk_title")
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_risk])
    @periods = periods_for_interval
    @audit_types = [
      [:internal, BusinessUnitType.list.internal_audit.map {|but| [but.name, but.id]}],
      [:external, BusinessUnitType.list.external_audit.map {|but| [but.name, but.id]}]
    ]
    @tables_data = {}
    statuses = Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).
      sort { |s1, s2| s1.last <=> s2.last }

    @repeated_counts = {}
    @being_implemented_resumes = {}
    @highest_being_implemented_resumes = {}
    highest_risk = RISK_TYPES.sort {|r1, r2| r1[1] <=> r2[1]}.last

    @periods.each do |period|
      total_weaknesses_count = {}
      total_weaknesses_count_by_risk = {}

      total_repeated_count = 0
      total_being_implemented_counts = {:current => 0, :stale => 0,
        :current_rescheduled => 0, :stale_rescheduled => 0}
      total_highest_being_implemented_counts = {:current => 0, :stale => 0,
        :current_rescheduled => 0, :stale_rescheduled => 0}

      @audit_types.each do |audit_type|
        weaknesses_count = {}
        weaknesses_count_by_risk = {}
        audit_type_symbol = audit_type.first

        unless audit_type.last.empty?
          audit_type.last.each do |audit_types|
            key = "#{audit_type_symbol}_#{audit_types.last}"
            conditions = {"#{BusinessUnitType.table_name}.id" => audit_types.last}
            being_implemented_counts = {:current => 0, :stale => 0,
              :current_rescheduled => 0, :stale_rescheduled => 0}
            highest_being_implemented_counts = {:current => 0, :stale => 0,
              :current_rescheduled => 0, :stale_rescheduled => 0}
            audit_type_symbol = audit_type.kind_of?(Symbol) ?
              audit_type : audit_type.first
            repeated_count = Finding.list_all_by_date(
              @from_date, @to_date, false).send(
              "#{audit_type_symbol}_audit").finals(false).repeated.for_period(
              period).where(conditions).count

            RISK_TYPES.each do |rl|
              weaknesses_count_by_risk[rl[0]] = 0
              total_weaknesses_count_by_risk[rl[0]] ||= 0

              statuses.each do |s|
                weaknesses_count[s[1]] ||= {}
                weaknesses_count[s[1]][rl[1]] = Weakness.list_all_by_date(
                  @from_date, @to_date, false).with_status_for_report.send(
                  "#{audit_type_symbol}_audit").for_period(period).finals(
                  final).where(
                    {:state => s[1], :risk => rl[1]}.merge(conditions || {})
                  ).count
                weaknesses_count_by_risk[rl[0]] += weaknesses_count[s[1]][rl[1]]
                total_weaknesses_count_by_risk[rl[0]] +=
                  weaknesses_count[s[1]][rl[1]]

                total_weaknesses_count[s[1]] ||= {}
                total_weaknesses_count[s[1]][rl[1]] ||= 0
                total_weaknesses_count[s[1]][rl[1]] +=
                  weaknesses_count[s[1]][rl[1]]

                if s.first.to_s == 'being_implemented'
                  being_implemented = Weakness.with_status_for_report.
                    list_all_by_date(@from_date, @to_date, false).send(
                    "#{audit_type_symbol}_audit").finals(false).for_period(
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
              weaknesses_count, weaknesses_count_by_risk, RISK_TYPES)
          end
        end
      end

      @repeated_counts[period]['total'] = total_repeated_count
      @being_implemented_resumes[period]['total'] =
        being_implemented_resume_from_counts(total_being_implemented_counts)
      @highest_being_implemented_resumes[period]['total'] =
        being_implemented_resume_from_counts(
          total_highest_being_implemented_counts)

      @tables_data[period]['total'] = get_weaknesses_synthesis_table_data(
        total_weaknesses_count, total_weaknesses_count_by_risk, RISK_TYPES)
    end
  end

  def create_weaknesses_by_risk
    self.weaknesses_by_risk

    pdf = init_pdf(params[:report_title], params[:report_subtitle])

    add_pdf_description(pdf, @controller, @from_date, @to_date)

    @periods.each do |period|
      add_period_title(pdf, period)

      @audit_types.each do |audit_type|
        audit_type_symbol = audit_type.kind_of?(Symbol) ?
          audit_type : audit_type.first

        unless audit_type.last.empty?

          pdf.move_down PDF_FONT_SIZE * 2

          pdf.add_title t("conclusion_committee_report.weaknesses_type_#{audit_type_symbol}"),
            (PDF_FONT_SIZE * 1.25).round, :center

          audit_type.last.each do |audit_types|
            key = "#{audit_type_symbol}_#{audit_types.last}"

            pdf.move_down PDF_FONT_SIZE
            pdf.add_title audit_types.first, PDF_FONT_SIZE, :left
            pdf.move_down PDF_FONT_SIZE

            add_weaknesses_synthesis_table(pdf, @tables_data[period][key])

            add_being_implemented_resume(pdf,
              @being_implemented_resumes[period][key])
            add_being_implemented_resume(pdf,
              @highest_being_implemented_resumes[period][key], 2)

            if @repeated_counts[period][key] > 0
              pdf.move_down((PDF_FONT_SIZE * 0.5).round)
              pdf.text t('follow_up_committee.repeated_count',
                :count => @repeated_counts[period][key],
                :font_size => PDF_FONT_SIZE)
            end
          end
        end
      end

      pdf.move_down PDF_FONT_SIZE
      pdf.add_title(
        t("#{@controller}_committee_report.weaknesses_by_risk.period_summary",
          :period => period.inspect), (PDF_FONT_SIZE * 1.25).round, :center
      )
      pdf.move_down PDF_FONT_SIZE

      add_weaknesses_synthesis_table(pdf, @tables_data[period]['total'])
    
      add_being_implemented_resume(pdf,
        @being_implemented_resumes[period]['total'])
      add_being_implemented_resume(pdf,
        @highest_being_implemented_resumes[period]['total'], 2)

      if @repeated_counts[period]['total'] > 0
        pdf.move_down((PDF_FONT_SIZE * 0.5).round)
        pdf.text t('follow_up_committee.repeated_count',
          :count => @repeated_counts[period]['total'],
          :font_size => PDF_FONT_SIZE)
      end
    end

    save_pdf(pdf, @controller, @from_date, @to_date, 'weaknesses_by_risk')

    redirect_to_pdf(@controller, @from_date, @to_date, 'weaknesses_by_risk')
  end
end
