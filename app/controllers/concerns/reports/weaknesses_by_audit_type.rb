module Reports::WeaknessesByAuditType
  include Reports::PDF
  include Reports::Period
  include Parameters::Risk

  def weaknesses_by_audit_type
    @controller = params[:controller_name]
    @final = params[:final] == 'true'
    @title = t("#{@controller}_committee_report.weaknesses_by_audit_type_title")
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
              repeated_count = 0

              cfrs.sort! {|cfr1, cfr2| cfr1.review.score <=> cfr2.review.score}

              cfrs.each do |cfr|
                review = cfr.review
                weaknesses |= @final ? review.final_weaknesses : review.weaknesses
                oportunities |= @final ? review.final_oportunities : review.oportunities
                repeated_count += review.weaknesses.repeated.count +
                  review.oportunities.repeated.count
              end

              grouped_weaknesses = weaknesses.group_by(&:state)
              grouped_oportunities = oportunities.group_by(&:state)
              oportunities_table_data = []
              weaknesses_count = {}
              weaknesses_count_by_risk = {}
              total_oportunities = grouped_oportunities.values.sum(&:size)
              awaiting_counts = {:current => 0, :stale => 0,
                :current_rescheduled => 0, :stale_rescheduled => 0}
              being_implemented_counts = {:current => 0, :stale => 0,
                :current_rescheduled => 0, :stale_rescheduled => 0}
              highest_awaiting_counts = {:current => 0, :stale => 0,
                :current_rescheduled => 0, :stale_rescheduled => 0}
              highest_being_implemented_counts = {:current => 0, :stale => 0,
                :current_rescheduled => 0, :stale_rescheduled => 0}

              if total_oportunities > 0
                statuses.each do |s|
                  o_count = (grouped_oportunities[s[1]] || []).size
                  oportunities_percentage = total_oportunities > 0 ?
                    o_count.to_f / total_oportunities * 100 : 0.0

                  oportunities_table_data << [
                    "<b>#{t("findings.state.#{s[0]}")}</b>",
                    "#{o_count} (#{'%.2f' % oportunities_percentage.round(2)}%)"
                  ]
                end

                oportunities_table_data << [
                  "<b>#{t("#{@controller}_committee_report.weaknesses_by_audit_type.total")}</b>",
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

                  if s.first.to_s == 'awaiting'
                    awaiting = weaknesses_for_status.select do |w|
                      w.risk == rl[1]
                    end

                    fill_counts_for rl, highest_risk, awaiting, awaiting_counts,
                      highest_awaiting_counts
                  elsif s.first.to_s == 'being_implemented'
                    being_implemented = weaknesses_for_status.select do |w|
                      w.risk == rl[1]
                    end

                    fill_counts_for rl, highest_risk, being_implemented,
                      being_implemented_counts, highest_being_implemented_counts
                  end
                end
              end

              weaknesses_table_data = get_weaknesses_synthesis_table_data(
                @final, weaknesses_count, weaknesses_count_by_risk, RISK_TYPES)
              awaiting_resume = being_implemented_resume_from_counts(
                awaiting_counts)
              being_implemented_resume = being_implemented_resume_from_counts(
                being_implemented_counts)
              highest_awaiting_resume = being_implemented_resume_from_counts(
                highest_awaiting_counts)
              highest_being_implemented_resume =
                being_implemented_resume_from_counts(
                  highest_being_implemented_counts)

              business_units[business_unit] = {
                :conclusion_reviews => cfrs,
                :weaknesses_table_data => weaknesses_table_data,
                :oportunities_table_data => oportunities_table_data,
                :repeated_count => repeated_count,
                :awaiting_resume => awaiting_resume,
                :being_implemented_resume => being_implemented_resume,
                :highest_awaiting_resume => highest_awaiting_resume,
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

    pdf = init_pdf(params[:report_title], params[:report_subtitle])

    add_pdf_description(pdf, @controller, @from_date, @to_date)

    @periods.each do |period|
      add_period_title(pdf, period)

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

              pdf.text "<b>#{t('actioncontroller.reviews')}</b>",
                :inline_format => true
              pdf.move_down PDF_FONT_SIZE

              bu_data[:conclusion_reviews].each do |cr|

                if @final
                  findings_count = cr.review.final_weaknesses.size +
                    cr.review.final_oportunities.size
                else
                  findings_count = cr.review.weaknesses.size +
                    cr.review.oportunities.size
                end

                text = "• <b>#{cr.review}</b>: " +
                  cr.review.reload.score_text

                if findings_count == 0
                  text << " (#{t("#{@controller}_committee_report.weaknesses_by_audit_type.without_weaknesses")})"
                end

                pdf.text text, :indent_paragraphs => PDF_FONT_SIZE * 2, :inline_format => true
              end

              pdf.move_down PDF_FONT_SIZE

              pdf.add_title(
                t("#{@controller}_committee_report.weaknesses_by_audit_type.weaknesses"),
                PDF_FONT_SIZE)

              pdf.move_down PDF_FONT_SIZE

              add_weaknesses_synthesis_table(pdf,
                bu_data[:weaknesses_table_data], 10)
              add_being_implemented_resume(pdf,
                bu_data[:being_implemented_resume])
              add_being_implemented_resume(pdf,
                bu_data[:highest_being_implemented_resume], 2)
              add_being_implemented_resume(pdf,
                bu_data[:awaiting_resume], 3)
              add_being_implemented_resume(pdf,
                bu_data[:highest_awaiting_resume], 4)

              if type == :internal
                pdf.move_down PDF_FONT_SIZE

                pdf.add_title(
                  t("#{@controller}_committee_report.weaknesses_by_audit_type.oportunities"),
                  PDF_FONT_SIZE)

                pdf.move_down PDF_FONT_SIZE

                unless bu_data[:oportunities_table_data].blank?
                  column_widths, column_headers = [], []
                  column_order = [
                    [Oportunity.human_attribute_name('state'), 30],
                    [Oportunity.human_attribute_name('count'), 70]
                  ]

                  column_order.each do |col_name, col_width|
                    column_headers << "<b>#{col_name}</b>"
                    column_widths << pdf.percent_width(col_width)
                  end

                  pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
                    table_options = pdf.default_table_options(column_widths)

                    pdf.table(bu_data[:oportunities_table_data].insert(0, column_headers), table_options) do
                      row(0).style(
                        :background_color => 'cccccc',
                        :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
                      )
                    end
                  end
                else
                  pdf.text t('follow_up_committee_report.without_oportunities'), :style => :italic
                end
              end

              if bu_data[:repeated_count] > 0
                pdf.move_down((PDF_FONT_SIZE * 0.5).round)
                pdf.text t('follow_up_committee_report.repeated_count',
                  :count => bu_data[:repeated_count],
                  :font_size => PDF_FONT_SIZE)
              end
            end
          end
        else
          pdf.text t('follow_up_committee_report.without_weaknesses'), :style => :italic
        end
      end
    end

    save_pdf(pdf, @controller, @from_date, @to_date, 'weaknesses_by_audit_type')

    redirect_to_pdf(@controller, @from_date, @to_date, 'weaknesses_by_audit_type')
  end

end
