module Reports::WeaknessesByRisk
  include Reports::Pdf
  include Reports::Period
  include Parameters::Risk

  def weaknesses_by_risk
    @controller = params[:controller_name]
    final = params[:final] == 'true'
    weaknesses_params = params[:weaknesses_by_risk] || {}
    @title = t("#{@controller}_committee_report.weaknesses_by_risk_title")
    @from_date, @to_date = *make_date_range(weaknesses_params)
    @periods = periods_for_interval
    @filters = []
    @audit_types = [
      [:internal, BusinessUnitType.list.internal_audit.map {|but| [but.name, but.id]}],
      [:external, BusinessUnitType.list.external_audit.map {|but| [but.name, but.id]}]
    ]
    @tables_data = {}
    statuses = Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).
      sort { |s1, s2| s1.last <=> s2.last }

    @repeated_counts = {}
    @awaiting_resumes = {}
    @being_implemented_resumes = {}
    @highest_awaiting_resumes = {}
    @highest_being_implemented_resumes = {}
    highest_risk = RISK_TYPES.sort { |r1, r2| r1[1] <=> r2[1] }.last

    if weaknesses_params[:repeated].present?
      repeated = weaknesses_params[:repeated] == 'true'

      @filters << "<b>#{t 'findings.state.repeated'}</b>: " +
        t("label.#{repeated ? 'yes' : 'no'}")
    end

    if weaknesses_params[:compliance].present?
      compliance = weaknesses_params[:compliance] == 'yes'

      @filters << "<b>#{Weakness.human_attribute_name 'compliance' }</b>: " +
        t("label.#{compliance ? 'yes' : 'no'}")
    end

    @periods.each do |period|
      total_weaknesses_count = {}
      total_weaknesses_count_by_risk = {}

      total_repeated_count = 0
      total_awaiting_counts = {:current => 0, :stale => 0,
        :current_rescheduled => 0, :stale_rescheduled => 0}
      total_being_implemented_counts = {:current => 0, :stale => 0,
        :current_rescheduled => 0, :stale_rescheduled => 0}
      total_highest_awaiting_counts = {:current => 0, :stale => 0,
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
            awaiting_counts = {:current => 0, :stale => 0,
              :current_rescheduled => 0, :stale_rescheduled => 0}
            being_implemented_counts = {:current => 0, :stale => 0,
              :current_rescheduled => 0, :stale_rescheduled => 0}
            highest_awaiting_counts = {:current => 0, :stale => 0,
              :current_rescheduled => 0, :stale_rescheduled => 0}
            highest_being_implemented_counts = {:current => 0, :stale => 0,
              :current_rescheduled => 0, :stale_rescheduled => 0}
            audit_type_symbol = audit_type.kind_of?(Symbol) ?
              audit_type : audit_type.first

            if weaknesses_params[:compliance].present?
              conditions[:compliance] = weaknesses_params[:compliance]
            end

            repeated_count = weaknesses_by_risk_scope(
              period: period,
              audit_type: audit_type_symbol,
              final: final,
              conditions: conditions
            ).repeated.count

            RISK_TYPES.each do |rl|
              weaknesses_count_by_risk[rl[0]] = 0
              total_weaknesses_count_by_risk[rl[0]] ||= 0

              statuses.each do |s|
                weaknesses_count[s[1]] ||= {}
                weaknesses_count[s[1]][rl[1]] = weaknesses_by_risk_scope(
                  period: period,
                  audit_type: audit_type_symbol,
                  final: final,
                  conditions: {
                    :state => s[1],
                    :risk => rl[1]
                  }.merge(conditions || {})
                ).with_status_for_report.count
                weaknesses_count_by_risk[rl[0]] += weaknesses_count[s[1]][rl[1]]
                total_weaknesses_count_by_risk[rl[0]] +=
                  weaknesses_count[s[1]][rl[1]]

                total_weaknesses_count[s[1]] ||= {}
                total_weaknesses_count[s[1]][rl[1]] ||= 0
                total_weaknesses_count[s[1]][rl[1]] +=
                  weaknesses_count[s[1]][rl[1]]

                if s.first.to_s == 'awaiting'
                  awaiting = weaknesses_by_risk_scope(
                    period: period,
                    audit_type: audit_type_symbol,
                    final: final,
                    conditions: {:risk => rl[1]}.merge(conditions || {})
                  ).with_status_for_report.awaiting

                  fill_counts_for rl, highest_risk, awaiting, awaiting_counts,
                    highest_awaiting_counts
                elsif s.first.to_s == 'being_implemented'
                  being_implemented = weaknesses_by_risk_scope(
                    period: period,
                    audit_type: audit_type_symbol,
                    final: final,
                    conditions: {:risk => rl[1]}.merge(conditions || {})
                  ).with_status_for_report.being_implemented

                  fill_counts_for rl, highest_risk, being_implemented,
                    being_implemented_counts, highest_being_implemented_counts
                end
              end
            end

            awaiting_counts.each do |type, count|
              total_awaiting_counts[type] += count
            end

            being_implemented_counts.each do |type, count|
              total_being_implemented_counts[type] += count
            end

            highest_awaiting_counts.each do |type, count|
              total_highest_awaiting_counts[type] += count
            end

            highest_being_implemented_counts.each do |type, count|
              total_highest_being_implemented_counts[type] += count
            end

            total_repeated_count += repeated_count

            @repeated_counts[period] ||= {}
            @repeated_counts[period][key] = repeated_count
            @awaiting_resumes[period] ||= {}
            @awaiting_resumes[period][key] ||=
              being_implemented_resume_from_counts(awaiting_counts)
            @being_implemented_resumes[period] ||= {}
            @being_implemented_resumes[period][key] =
              being_implemented_resume_from_counts(being_implemented_counts)
            @highest_awaiting_resumes[period] ||= {}
            @highest_awaiting_resumes[period][key] ||=
              being_implemented_resume_from_counts(highest_awaiting_counts)
            @highest_being_implemented_resumes[period] ||= {}
            @highest_being_implemented_resumes[period][key] =
              being_implemented_resume_from_counts(highest_being_implemented_counts)

            @tables_data[period] ||= {}
            @tables_data[period][key] = get_weaknesses_synthesis_table_data(
              final, weaknesses_count, weaknesses_count_by_risk, RISK_TYPES)
          end
        end
      end

      @repeated_counts[period]['total'] = total_repeated_count
      @awaiting_resumes[period]['total'] =
        being_implemented_resume_from_counts(total_awaiting_counts)
      @being_implemented_resumes[period]['total'] =
        being_implemented_resume_from_counts(total_being_implemented_counts)
      @highest_awaiting_resumes[period]['total'] =
        being_implemented_resume_from_counts(total_highest_awaiting_counts)
      @highest_being_implemented_resumes[period]['total'] =
        being_implemented_resume_from_counts(
          total_highest_being_implemented_counts)

      @tables_data[period]['total'] = get_weaknesses_synthesis_table_data(
        final, total_weaknesses_count, total_weaknesses_count_by_risk, RISK_TYPES)
    end
  end

  def create_weaknesses_by_risk
    self.weaknesses_by_risk

    pdf = init_pdf(params[:report_title], params[:report_subtitle])

    add_pdf_description(pdf, @controller, @from_date, @to_date)

    @periods.each do |period|
      add_period_title(pdf, period)

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
      add_being_implemented_resume(pdf,
        @awaiting_resumes[period]['total'], 3)
      add_being_implemented_resume(pdf,
        @highest_awaiting_resumes[period]['total'], 4)

      if @repeated_counts[period]['total'] > 0
        pdf.move_down((PDF_FONT_SIZE * 0.5).round)
        pdf.text t('follow_up_committee_report.repeated_count',
          :count => @repeated_counts[period]['total'],
          :font_size => PDF_FONT_SIZE)
      end

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
            add_being_implemented_resume(pdf,
              @awaiting_resumes[period][key], 3)
            add_being_implemented_resume(pdf,
              @highest_awaiting_resumes[period][key], 4)

            if @repeated_counts[period][key] > 0
              pdf.move_down((PDF_FONT_SIZE * 0.5).round)
              pdf.text t('follow_up_committee_report.repeated_count',
                :count => @repeated_counts[period][key],
                :font_size => PDF_FONT_SIZE)
            end
          end
        end
      end
    end

    add_pdf_filters(pdf, @controller, @filters) if @filters.present?

    save_pdf(pdf, @controller, @from_date, @to_date, 'weaknesses_by_risk')

    redirect_to_pdf(@controller, @from_date, @to_date, 'weaknesses_by_risk')
  end

  private

    def weaknesses_by_risk_scope final: false, conditions: {}, period:, audit_type:
      weaknesses_params = params[:weaknesses_by_risk] || {}
      scope = Weakness.
        list_all_by_date(@from_date, @to_date, false).
        send("#{audit_type}_audit").
        finals(final).
        for_period(period).
        where(conditions)

      if weaknesses_params[:repeated].present?
        if weaknesses_params[:repeated] == 'true'
          scope.where.not(repeated_of: nil)
        else
          scope.where(repeated_of: nil)
        end
      else
        scope
      end
    end
end
