module Reports::WeaknessesByAuditType
  extend ActiveSupport::Concern

  include Reports::Pdf
  include Reports::Period

  def weaknesses_by_audit_type(final = false, controller = 'conclusion')
    @controller = controller
    @title = t("#{@controller}_committee_report.weaknesses_by_audit_type_title")
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_audit_type])
    @periods = periods_for_interval
    @audit_types = [:internal, :external]
    @data = {}
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
                weaknesses |= final ? review.final_weaknesses : review.weaknesses
                oportunities |= final ? review.final_oportunities : review.oportunities
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

                  oportunities_table_data << [
                    "<b>#{t("finding.status_#{s[0]}")}</b>",
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
                end
              end

              weaknesses_table_data = get_weaknesses_synthesis_table_data(
                weaknesses_count, weaknesses_count_by_risk, RISK_TYPES)

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

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE * 2

    pdf.add_description_item(
      t("#{@controller}_committee_report.period.title"),
      t("#{@controller}_committee_report.period.range",
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_down PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :left

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
              
                if final  
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

                pdf.text text, :left => PDF_FONT_SIZE * 2, :inline_format => true
              end

              pdf.move_down PDF_FONT_SIZE

              pdf.add_title(
                t("#{@controller}_committee_report.weaknesses_by_audit_type.weaknesses"),
                PDF_FONT_SIZE)

              pdf.move_down PDF_FONT_SIZE

              add_weaknesses_synthesis_table(pdf,
                bu_data[:weaknesses_table_data], 10)

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
                  pdf.text t('follow_up_committee.without_oportunities'), :style => :italic
                end
              end
            end
          end
        else
          pdf.text t('follow_up_committee.without_weaknesses'), :style => :italic
        end
      end
    end

    pdf.custom_save_as(
      t("#{@controller}_committee_report.weaknesses_by_audit_type.pdf_name",
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)),
      'weaknesses_by_audit_type', 0)

    redirect_to Prawn::Document.relative_path(
      t("#{@controller}_committee_report.weaknesses_by_audit_type.pdf_name",
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)),
      'weaknesses_by_audit_type', 0)
  end
end
