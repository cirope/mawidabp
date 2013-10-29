module FollowUpCommonReports
  include Parameters::Risk

  def weaknesses_by_state
    @title = t 'follow_up_committee.weaknesses_by_state_title'
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_state])
    @periods = periods_for_interval
    @sqm = @auth_organization.kind.eql? 'quality_management'
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

        unless audit_type.last.empty?
          audit_type.last.each do |audit_types|
            key = "#{audit_type_symbol}_#{audit_types.last}"
            conditions = {"#{BusinessUnitType.table_name}.id" => audit_types.last}
            @weaknesses_counts[period]['total_weaknesses'] ||= {}
            @weaknesses_counts[period]['total_oportunities'] ||= {}

            @weaknesses_counts[period]["#{key}_weaknesses"] =
              Weakness.with_status_for_report.list_all_by_date(
              @from_date, @to_date, false).send(
              "#{audit_type_symbol}_audit").finals(false).for_period(
              period).where(conditions).group(:state).count
            @weaknesses_counts[period]["#{key}_oportunities"] =
              Oportunity.with_status_for_report.list_all_by_date(
              @from_date, @to_date, false).send(
              "#{audit_type_symbol}_audit").finals(false).for_period(
              period).where(conditions).group(:state).count
            @weaknesses_counts[period]["#{key}_repeated"] =
              Finding.list_all_by_date(@from_date, @to_date, false).send(
              "#{audit_type_symbol}_audit").finals(false).for_period(
              period).repeated.where(conditions).count
            if @sqm
              @weaknesses_counts[period]['total_nonconformities'] ||= {}
              @weaknesses_counts[period]['total_potential_nonconformities'] ||= {}

              @weaknesses_counts[period]["#{key}_nonconformities"] =
                Nonconformity.list_all_by_date(@from_date, @to_date, false).
                with_status_for_report.send("#{audit_type_symbol}_audit").
                for_period(period).finals(false).where(conditions).group(
                :state).count
              @weaknesses_counts[period]["#{key}_potential_nonconformities"] =
                PotentialNonconformity.list_all_by_date(@from_date, @to_date, false).
                with_status_for_report.send("#{audit_type_symbol}_audit").
                for_period(period).finals(false).where(conditions).group(
                :state).count

              @weaknesses_counts[period]["#{key}_nonconformities"].each do |state, count|
                @weaknesses_counts[period]['total_nonconformities'][state] ||= 0
                @weaknesses_counts[period]['total_nonconformities'][state] += count
              end

              @weaknesses_counts[period]["#{key}_potential_nonconformities"].each do |state, count|
                @weaknesses_counts[period]['total_potential_nonconformities'][state] ||= 0
                @weaknesses_counts[period]['total_potential_nonconformities'][state] += count
              end
            end
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
              if state.first.to_s == 'being_implemented'
                being_implemented = Weakness.with_status_for_report.
                  list_all_by_date(@from_date, @to_date, false).send(
                  "#{audit_type_symbol}_audit").finals(false).for_period(
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
      end

      @being_implemented_resumes[period]['total'] =
        being_implemented_resume_from_counts(total_being_implemented_counts)
    end
  end

  def create_weaknesses_by_state
    self.weaknesses_by_state

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE * 2

    pdf.add_description_item(
      t('follow_up_committee.period.title'),
      t('follow_up_committee.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_down PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :justify

      @audit_types.each do |audit_type|
        audit_type_symbol = audit_type.first

        unless audit_type.last.empty?
          pdf.move_down PDF_FONT_SIZE * 2

          pdf.add_title t("conclusion_committee_report.findings_type_#{audit_type_symbol}"),
            (PDF_FONT_SIZE * 1.25).round, :center

          audit_type.last.each do |audit_types|
            key = "#{audit_type_symbol}_#{audit_types.last}"

            pdf.move_down PDF_FONT_SIZE
            pdf.add_title audit_types.first, PDF_FONT_SIZE, :justify
            pdf.move_down PDF_FONT_SIZE

            weaknesses_count = @weaknesses_counts[period]["#{key}_weaknesses"]
            oportunities_count = @weaknesses_counts[period]["#{key}_oportunities"]
            repeated_count = @weaknesses_counts[period]["#{key}_repeated"]

            if @sqm
              nonconformities_count = @weaknesses_counts[period]["#{key}_nonconformities"]
              potential_nonconformities_count = @weaknesses_counts[period]["#{key}_potential_nonconformities"]

              add_weaknesses_by_state_table(pdf, weaknesses_count, oportunities_count,
                repeated_count, @being_implemented_resumes[period][key], audit_type_symbol,
                nonconformities_count, potential_nonconformities_count, @sqm)
            else
              add_weaknesses_by_state_table(pdf, weaknesses_count,
                oportunities_count, repeated_count,
                @being_implemented_resumes[period][key], audit_type_symbol)
            end
          end
        end
      end

      pdf.move_down PDF_FONT_SIZE
      pdf.add_title(
        t('follow_up_committee.weaknesses_by_state.period_summary',
          :period => period.inspect), (PDF_FONT_SIZE * 1.25).round, :center
      )
      pdf.move_down PDF_FONT_SIZE

      weaknesses_count = @weaknesses_counts[period]['total_weaknesses']
      oportunities_count = @weaknesses_counts[period]['total_oportunities']
      repeated_count = @weaknesses_counts[period]['total_repeated']

      add_weaknesses_by_state_table pdf, weaknesses_count, oportunities_count,
        repeated_count, @being_implemented_resumes[period]['total']
    end

    pdf.custom_save_as(
      t('follow_up_committee.weaknesses_by_state.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'weaknesses_by_state', 0)

    redirect_to Prawn::Document.relative_path(
      t('follow_up_committee.weaknesses_by_state.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'weaknesses_by_state', 0)
  end

  def weaknesses_by_risk
    @title = t 'follow_up_committee.weaknesses_by_risk_title'
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
    statuses = Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).
      sort { |s1, s2| s1.last <=> s2.last }
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
        unless audit_type.last.empty?
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
              "#{audit_type_symbol}_audit").finals(false).repeated.for_period(
              period).where(conditions).count

            RISK_TYPES.each do |rl|
              weaknesses_count_by_risk[rl[0]] = 0
              total_weaknesses_count_by_risk[rl[0]] ||= 0

              statuses.each do |s|
                weaknesses_count[s[1]] ||= {}
                weaknesses_count[s[1]][rl[1]] =
                  Weakness.with_status_for_report.list_all_by_date(
                  @from_date, @to_date, false).send(
                  "#{audit_type_symbol}_audit").finals(false).for_period(
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

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE * 2

    pdf.add_description_item(
      t('follow_up_committee.period.title'),
      t('follow_up_committee.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_down PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :justify

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
            pdf.add_title audit_types.first, PDF_FONT_SIZE, :justify
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
        t('follow_up_committee.weaknesses_by_risk.period_summary',
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

    pdf.custom_save_as(
      t('follow_up_committee.weaknesses_by_risk.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'weaknesses_by_risk', 0)

    redirect_to Prawn::Document.relative_path(
      t('follow_up_committee.weaknesses_by_risk.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'weaknesses_by_risk', 0)
  end

  def weaknesses_by_audit_type
    @title = t 'follow_up_committee.weaknesses_by_audit_type_title'
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_audit_type])
    @periods = periods_for_interval
    @audit_types = [:internal, :external]
    @data = {}
    statuses = Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).
      sort { |s1, s2| s1.last <=> s2.last }
    highest_risk = RISK_TYPES.sort {|r1, r2| r1[1] <=> r2[1]}.last

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

                  oportunities_table_data << [
                    "<b>#{t(:"finding.status_#{s[0]}")}</b>",
                    "#{o_count} (#{'%.2f' % oportunities_percentage.round(2)}%)"
                  ]
                end

                oportunities_table_data << [
                  "<b>#{t('conclusion_committee_report.weaknesses_by_audit_type.total')}</b>",
                  "<b>#{total_oportunities}</b>"
                ]
              end

              RISK_TYPES.each do |rl|
                weaknesses_count_by_risk[rl[0]] = 0

                statuses.each do |s|
                  weaknesses_for_status = grouped_weaknesses[s[1]] || {}

                  count_for_risk = weaknesses_for_status.inject(0) do |sum, w|
                    sum + (w.risk == rl[1] ? 1 : 0)
                  end

                  weaknesses_count[s[1]] ||= {}
                  weaknesses_count[s[1]][rl[1]] = count_for_risk
                  weaknesses_count_by_risk[rl[0]] += weaknesses_count[s[1]][rl[1]]

                  if s.first.to_s == 'being_implemented'
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
                weaknesses_count, weaknesses_count_by_risk, RISK_TYPES)
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

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE * 2

    pdf.add_description_item(
      t('follow_up_committee.period.title'),
      t('follow_up_committee.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_down PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round

      @audit_types.each do |type|
        pdf.move_down PDF_FONT_SIZE * 2

        pdf.add_title t("conclusion_committee_report.findings_type_#{type}"),
          (PDF_FONT_SIZE * 1.25).round, :center

        pdf.move_down PDF_FONT_SIZE

        unless @data[period][type].blank?
          @data[period][type].each do |data_item|
            pdf.move_down PDF_FONT_SIZE
            pdf.add_title data_item[:title], PDF_FONT_SIZE, :center

            data_item[:business_units].each do |bu, bu_data|
              pdf.move_down PDF_FONT_SIZE

              pdf.add_description_item(
                bu.business_unit_type.business_unit_label, bu.name)
              pdf.move_down PDF_FONT_SIZE

              pdf.text "<b>#{t('actioncontroller.reviews')}</b>", :inline_format => true
              pdf.move_down PDF_FONT_SIZE

              bu_data[:conclusion_reviews].each do |cr|
                findings_count = cr.review.weaknesses.size +
                  cr.review.oportunities.size

                text = "• <b>#{cr.review}</b>: " +
                  cr.review.reload.score_text

                if findings_count == 0
                  text << " (#{t('follow_up_committee.weaknesses_by_audit_type.without_weaknesses')})"
                end

                pdf.text text, :left => PDF_FONT_SIZE * 2, :inline_format => true
              end

              pdf.move_down PDF_FONT_SIZE

              pdf.add_title(
                t('follow_up_committee.weaknesses_by_audit_type.weaknesses'),
                PDF_FONT_SIZE)

              pdf.move_down PDF_FONT_SIZE

              add_weaknesses_synthesis_table(pdf,
                bu_data[:weaknesses_table_data], 10)
              add_being_implemented_resume(pdf,
                bu_data[:being_implemented_resume])
              add_being_implemented_resume(pdf,
                bu_data[:highest_being_implemented_resume], 2)

              if type == :internal
                pdf.move_down PDF_FONT_SIZE

                pdf.add_title(
                  t('follow_up_committee.weaknesses_by_audit_type.oportunities'),
                  PDF_FONT_SIZE)

                pdf.move_down PDF_FONT_SIZE

                unless bu_data[:oportunities_table_data].blank?
                  columns = {
                    'state' => [Oportunity.human_attribute_name(:state), 30],
                    'count' => [Oportunity.human_attribute_name(:count), 70]
                  }

                  column_headers, column_widths = [], []
                  columns.each_value do |col_data|
                    column_headers << "<b>#{col_data.first}</b>"
                    column_widths << pdf.percent_width(col_data.last)
                  end

                  unless bu_data[:oportunities_table_data].blank?
                    pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
                      table_options = pdf.default_table_options(column_widths)

                      pdf.table(bu_data[:oportunities_table_data].insert(0, column_headers), table_options) do
                        row(0).style(
                          :background_color => 'cccccc',
                          :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
                        )
                      end
                    end
                  end
                else
                    pdf.text t('follow_up_committee.without_oportunities')
                end
              end

              if bu_data[:repeated_count] > 0
                pdf.move_down((PDF_FONT_SIZE * 0.5).round)
                pdf.text t('follow_up_committee.repeated_count',
                  :count => bu_data[:repeated_count],
                  :font_size => PDF_FONT_SIZE)
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
      t('follow_up_committee.weaknesses_by_audit_type.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'weaknesses_by_audit_type',
      0)

    redirect_to Prawn::Document.relative_path(
      t('follow_up_committee.weaknesses_by_audit_type.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'weaknesses_by_audit_type',
      0)
  end

  def control_objective_stats
    @title = t('follow_up_committee.control_objective_stats_title')
    @from_date, @to_date = *make_date_range(params[:control_objective_stats])
    @periods = periods_for_interval
    @risk_levels = []
    @filters = []
    @columns = [
      ['process_control', BestPractice.human_attribute_name(:process_controls), 20],
      ['control_objective', ControlObjective.model_name.human, 40],
      ['effectiveness', t('follow_up_committee.control_objective_stats.average_effectiveness'), 20],
      ['weaknesses_count', t('review.weaknesses_count_by_state'), 20]
    ]
    conclusion_reviews = ConclusionFinalReview.list_all_by_date(
      @from_date, @to_date
    )
    @process_control_data = {}
    @control_objectives_data = {}
    @reviews_score_data = {}
    reviews_score_data = {}
    control_objectives = []

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

          coi.weaknesses.not_revoked.each do |w|
            @risk_levels |= RISK_TYPES.sort {|r1, r2| r2[1] <=> r1[1]}.map { |r| r.first }

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
          reviews_count = coi_data[:effectiveness].size
          effectiveness = reviews_count > 0 ?
            coi_data[:effectiveness].sum / reviews_count : 100
          weaknesses_count = coi_data[:weaknesses]

          if weaknesses_count.values.sum == 0
            weaknesses_count_text = t(
              'follow_up_committee.control_objective_stats.without_weaknesses'
            )
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
              @control_objectives_data[period][pc][co.name][risk_text][:complete].concat(
                coi_data[:weaknesses_ids][risk_text][:complete]
              )
              @control_objectives_data[period][pc][co.name][risk_text][:incomplete].concat(
                coi_data[:weaknesses_ids][risk_text][:incomplete]
              )
              weaknesses_count_text[risk_text.to_sym] = text[risk_text]
            end
          end

          @process_control_data[period] << {
            'process_control' => pc,
            'control_objective' => co.name,
            'effectiveness' => t(
              'follow_up_committee.control_objective_stats.average_effectiveness_resume',
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

    pdf.add_description_item(
      t('follow_up_committee.period.title'),
      t('follow_up_committee.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_down PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :justify

      pdf.move_down PDF_FONT_SIZE

      column_data, column_headers, column_widths = [], [], []
      columns = {}

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
          t('follow_up_committee.control_objective_stats.without_audits_in_the_period'))
      end

      pdf.move_down PDF_FONT_SIZE
      pdf.text t(
        'follow_up_committee.control_objective_stats.review_score_average',
        :score => @reviews_score_data[period]
      ), :inline_format => true
    end

    unless @filters.empty?
      pdf.move_down PDF_FONT_SIZE
      pdf.text t('follow_up_committee.applied_filters',
        :filters => @filters.to_sentence, :count => @filters.size),
        :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full,
        :inline_format => true
    end

    pdf.custom_save_as(
      t('follow_up_committee.control_objective_stats.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'control_objective_stats', 0)

    redirect_to Prawn::Document.relative_path(
      t('follow_up_committee.control_objective_stats.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'control_objective_stats', 0)
  end

  def process_control_stats
    @title = t('follow_up_committee.process_control_stats_title')
    @from_date, @to_date = *make_date_range(params[:process_control_stats])
    @periods = periods_for_interval
    @risk_levels = []
    @filters = []
    @columns = [
      ['process_control', BestPractice.human_attribute_name(:process_controls), 60],
      ['effectiveness', t('follow_up_committee.process_control_stats.average_effectiveness'), 20],
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

          coi.weaknesses.each do |w|
            @risk_levels |= RISK_TYPES.sort { |r1, r2| r2[1] <=> r1[1] }.map { |r| r.first }

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
            'follow_up_committee.process_control_stats.without_weaknesses'
          )
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
            'follow_up_committee.process_control_stats.average_effectiveness_resume',
            :effectiveness => "#{'%.2f' % effectiveness}%",
            :count => pc_data[:reviews]
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

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_description_item(
      t('follow_up_committee.period.title'),
      t('follow_up_committee.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_down PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :justify

      pdf.move_down PDF_FONT_SIZE

      column_data, column_headers, column_widths = [], [], []
      columns = {}

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
          t('follow_up_committee.process_control_stats.without_audits_in_the_period'))
      end

      pdf.move_down PDF_FONT_SIZE
      pdf.text t(
        'follow_up_committee.control_objective_stats.review_score_average',
        :score => @reviews_score_data[period]
      ), :inline_format => true
    end

    unless @filters.empty?
      pdf.move_down PDF_FONT_SIZE
      pdf.text t('follow_up_committee.applied_filters',
        :filters => @filters.to_sentence, :count => @filters.size),
        :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full,
        :inline_format => true
    end

    pdf.custom_save_as(
      t('follow_up_committee.process_control_stats.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'process_control_stats', 0)

    redirect_to Prawn::Document.relative_path(
      t('follow_up_committee.process_control_stats.pdf_name',
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
    ).references(:reviews)
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
      column_data, column_headers, column_widths = [], [], []

      data[:order].each do |column|
        col_data = data[:columns][column]
        column_headers << "<b>#{col_data.first}</b>"
        column_widths << pdf.percent_width(col_data.last)
      end

      data[:data].each do |row|
        new_row = []

        data[:order].each {|column| new_row << row[column]}

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
      end
    else
      pdf.text data, :style => :italic, :font_size => PDF_FONT_SIZE
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

      risk_levels.each {|rl| columns[rl[0]] = [t("risk_types.#{rl[0]}"), (55 / risk_levels.size)]}

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

          if count > 0 && rl == highest_risk && state[0].to_s == 'being_implemented'
            column_row[rl.first] << '**'
          end
        end

        column_row['count'] = sub_total_count > 0 ?
          "<b>#{sub_total_count} (#{'%.1f' % percentage_total}%)</b>" : '-'

        if state.first.to_s == 'being_implemented' && sub_total_count != 0
          column_row['count'] << '*'
        end

        column_data << column_row
      end

      column_row = {
        'state' => "<b>#{t('follow_up_committee.weaknesses_by_risk.total')}</b>",
        'count' => "<b>#{total_count}</b>"
      }

      weaknesses_count_by_risk.each do |risk, count|
        column_row[risk] = "<b>#{count}</b>"
      end

      column_data << column_row

      {:order => column_order, :data => column_data, :columns => columns}
    else
      t('follow_up_committee.without_weaknesses')
    end
  end

  def add_weaknesses_by_state_table(pdf, weaknesses_count, oportunities_count,
      repeated_count, being_implemented_resume, audit_type_symbol = :internal, nonconformities_count = nil,
      potential_nonconformities_count = nil, sqm = false)

    total_weaknesses = weaknesses_count.values.sum
    total_oportunities = oportunities_count.values.sum
    if sqm
      total_nonconformities = nonconformities_count.values.sum
      total_potential_nonconformities = potential_nonconformities_count.values.sum
      totals = total_weaknesses + total_oportunities + total_nonconformities +
        total_potential_nonconformities
    else
      totals = total_weaknesses + total_oportunities
    end

    if totals > 0
      columns = [
        [Finding.human_attribute_name(:state), 20],
        [t('conclusion_committee_report.weaknesses_by_state.weaknesses_column'), 20]
      ]
      column_data = []

      if audit_type_symbol == :internal && !sqm
        columns << [
          t('conclusion_committee_report.weaknesses_by_state.oportunities_column'), 20]
      elsif audit_type_symbol == :internal && sqm
        columns << [
          t('conclusion_committee_report.weaknesses_by_state.oportunities_column'), 20]
        columns << [
          t('conclusion_committee_report.weaknesses_by_state.nonconformities_column'), 20]
        columns << [
          t('conclusion_committee_report.weaknesses_by_state.potential_nonconformities_column'), 20]
      end

      column_headers, column_widths = [], []

      columns.each do |col_data|
        column_headers << "<b>#{col_data.first}</b>"
        column_widths << pdf.percent_width(col_data.last)
      end

      @status.each do |state|
        w_count = weaknesses_count[state.last] || 0
        o_count = oportunities_count[state.last] || 0
        weaknesses_percentage = total_weaknesses > 0 ?
          w_count.to_f / total_weaknesses * 100 : 0.0
        oportunities_percentage = total_oportunities > 0 ?
          o_count.to_f / total_oportunities * 100 : 0.0

        column_data << [
          "<b>#{t("finding.status_#{state.first}")}</b>",
          "#{w_count} (#{'%.2f' % weaknesses_percentage.round(2)}%)"
        ]

        if audit_type_symbol == :internal && !sqm
          column_data.last << "#{o_count} (#{'%.2f' % oportunities_percentage.round(2)}%)"
        elsif audit_type_symbol == :internal && sqm
          nc_count = nonconformities_count[state.last] || 0
          pnc_count = potential_nonconformities_count[state.last] || 0
          nonconformities_percentage = total_nonconformities > 0 ? nc_count.to_f / total_nonconformities * 100 : 0.0
          potential_nonconformities_percentage = total_potential_nonconformities > 0 ? pnc_count.to_f / total_potential_nonconformities * 100 : 0.0

          column_data.last << "#{o_count} (#{'%.2f' % oportunities_percentage.round(2)}%)"
          column_data.last << "#{nc_count} (#{'%.2f' % nonconformities_percentage.round(2)}%)"
          column_data.last << "#{pnc_count} (#{'%.2f' % potential_nonconformities_percentage.round(2)}%)"
        end

        if state.first.to_s == 'being_implemented'
          if column_data.last[1] != '0'
            column_data.last[1] << ' *'
          end
        end
      end

      column_data << [
        "<b>#{t('follow_up_committee.weaknesses_by_state.total')}</b>",
        "<b>#{total_weaknesses}</b>"
      ]

      if audit_type_symbol == :internal && !sqm
        column_data.last << "<b>#{total_oportunities}</b>"
      elsif audit_type_symbol == :internal && sqm
        column_data.last << "<b>#{total_oportunities}</b>"
        column_data.last << "<b>#{total_nonconformities}</b>"
        column_data.last << "<b>#{total_potential_nonconformities}</b>"
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
      end

      add_being_implemented_resume(pdf, being_implemented_resume)

      if repeated_count > 0
        pdf.move_down((PDF_FONT_SIZE * 0.5).round)
        pdf.text t('follow_up_committee.repeated_count',
          :count => repeated_count, :font_size => PDF_FONT_SIZE)
      end
    else
      pdf.text t('follow_up_committee.without_weaknesses'),
        :font_size => PDF_FONT_SIZE, :style => :italic
    end
  end

  def add_being_implemented_resume(pdf, being_implemented_resume = nil,
      asterisks = 1)
    unless being_implemented_resume.blank?
      pdf.move_down PDF_FONT_SIZE if asterisks == 1

      pdf.text(('*' * asterisks) + " #{being_implemented_resume}",
        :font_size => PDF_FONT_SIZE, :inline_format => true)
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
