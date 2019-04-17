module Reports::WeaknessesByState
  extend ActiveSupport::Concern

  include Reports::PDF
  include Reports::Period

  def weaknesses_by_state
    @controller = params[:controller_name]
    @final = params[:final] == 'true'
    @title = t("#{@controller}_committee_report.weaknesses_by_state_title")
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_state])
    @periods = periods_for_interval
    @weaknesses_counts = {}
    @awaiting_resumes = {}
    @being_implemented_resumes = {}
    @status = Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).
        sort { |s1, s2| s1.last <=> s2.last }
    @audit_types = [
      [:internal, BusinessUnitType.list.internal_audit.map {|but| [but.name, but.id]}],
      [:external, BusinessUnitType.list.external_audit.map {|but| [but.name, but.id]}]
    ]

    @periods.each do |period|
      @weaknesses_counts[period] ||= {}
      total_awaiting_counts = {:current => 0, :stale => 0,
                :current_rescheduled => 0, :stale_rescheduled => 0}
      total_being_implemented_counts = {:current => 0, :stale => 0,
                :current_rescheduled => 0, :stale_rescheduled => 0}

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
                for_period(period).finals(@final).where(conditions).group(:state).count
            @weaknesses_counts[period]["#{key}_oportunities"] =
              Oportunity.list_all_by_date(@from_date, @to_date, false).
              with_status_for_report.send("#{audit_type_symbol}_audit").
              for_period(period).finals(@final).where(conditions).group(
              :state).count
            @weaknesses_counts[period]["#{key}_repeated"] =
              Finding.list_all_by_date(@from_date, @to_date, false).send(
                "#{audit_type_symbol}_audit").finals(false).for_period(
                  period).repeated.where(conditions).count

            @weaknesses_counts[period]["#{key}_weaknesses"].each do |state, count|
              @weaknesses_counts[period]['total_weaknesses'][state] ||= 0
              @weaknesses_counts[period]['total_weaknesses'][state] += count
            end

            @weaknesses_counts[period]["#{key}_oportunities"].each do |state, count|
              @weaknesses_counts[period]['total_oportunities'][state] ||= 0
              @weaknesses_counts[period]['total_oportunities'][state] += count
            end

            awaiting_counts = {:current => 0, :stale => 0,
              :current_rescheduled => 0, :stale_rescheduled => 0}
            being_implemented_counts = {:current => 0, :stale => 0,
              :current_rescheduled => 0, :stale_rescheduled => 0}

            @weaknesses_counts[period]['total_repeated'] ||= 0
            @weaknesses_counts[period]['total_repeated'] +=
              @weaknesses_counts[period]["#{key}_repeated"]

            @status.each do |state|
              if state.first.to_s == 'awaiting'
                awaiting = Weakness.with_status_for_report.
                  list_all_by_date(@from_date, @to_date, false).send(
                  "#{audit_type_symbol}_audit").finals(@final).for_period(
                  period).awaiting.where(conditions)

                fill_state_counts_for awaiting, awaiting_counts
              elsif state.first.to_s == 'being_implemented'
                being_implemented = Weakness.with_status_for_report.
                  list_all_by_date(@from_date, @to_date, false).send(
                  "#{audit_type_symbol}_audit").finals(@final).for_period(
                  period).being_implemented.where(conditions)

                fill_state_counts_for being_implemented,
                  being_implemented_counts
              end
            end

            @awaiting_resumes[period] ||= {}
            @awaiting_resumes[period][key] =
              being_implemented_resume_from_counts(awaiting_counts)
            @being_implemented_resumes[period] ||= {}
            @being_implemented_resumes[period][key] =
              being_implemented_resume_from_counts(being_implemented_counts)

            awaiting_counts.each do |type, count|
              total_awaiting_counts[type] += count
            end

            being_implemented_counts.each do |type, count|
              total_being_implemented_counts[type] += count
            end
          end
        end
      end

      @awaiting_resumes[period]['total'] =
        being_implemented_resume_from_counts(total_awaiting_counts)
      @being_implemented_resumes[period]['total'] =
        being_implemented_resume_from_counts(total_being_implemented_counts)
    end
  end

  def create_weaknesses_by_state
    self.weaknesses_by_state

    pdf = init_pdf(params[:report_title], params[:report_subtitle])

    add_pdf_description(pdf, @controller, @from_date, @to_date)

    @periods.each do |period|
      add_period_title(pdf, period)

      pdf.move_down PDF_FONT_SIZE
      pdf.add_title(
        t("#{@controller}_committee_report.weaknesses_by_state.period_summary",
          :period => period.inspect), (PDF_FONT_SIZE * 1.25).round, :center
      )
      pdf.move_down PDF_FONT_SIZE

      weaknesses_count = @weaknesses_counts[period]['total_weaknesses']
      oportunities_count = @weaknesses_counts[period]['total_oportunities']
      repeated_count = @weaknesses_counts[period]['total_repeated']

      add_weaknesses_by_state_table pdf, @final, weaknesses_count,
        oportunities_count, repeated_count, @awaiting_resumes[period]['total'],
        @being_implemented_resumes[period]['total']

      @audit_types.each do |audit_type|
        audit_type_symbol = audit_type.first

        unless audit_type.last.empty?
          pdf.move_down PDF_FONT_SIZE * 2

          pdf.add_title t("conclusion_committee_report.findings_type_#{audit_type_symbol}"),
            (PDF_FONT_SIZE * 1.25).round, :center

          audit_type.last.each do |audit_types|
            key = "#{audit_type_symbol}_#{audit_types.last}"

            pdf.move_down PDF_FONT_SIZE
            pdf.add_title audit_types.first, PDF_FONT_SIZE, :left
            pdf.move_down PDF_FONT_SIZE

            weaknesses_count = @weaknesses_counts[period]["#{key}_weaknesses"]
            oportunities_count = @weaknesses_counts[period]["#{key}_oportunities"]
            repeated_count = @weaknesses_counts[period]["#{key}_repeated"]

            add_weaknesses_by_state_table(pdf, @final, weaknesses_count,
              oportunities_count, repeated_count,
              @awaiting_resumes[period][key],
              @being_implemented_resumes[period][key], audit_type_symbol)
          end
        end
      end
    end

    save_pdf(pdf, @controller, @from_date, @to_date, 'weaknesses_by_state')
    redirect_to_pdf(@controller, @from_date, @to_date, 'weaknesses_by_state')
  end

  private

    def fill_state_counts_for weaknesses, counts
      weaknesses.each do |w|
        unless w.stale?
          unless w.rescheduled?
            counts[:current] += 1
          else
            counts[:current_rescheduled] += 1
          end
        else
          unless w.rescheduled?
            counts[:stale] += 1
          else
            counts[:stale_rescheduled] += 1
          end
        end
      end
    end
end
