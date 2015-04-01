module Reports::NonconformitiesReport
  extend ActiveSupport::Concern

  include Reports::Pdf
  include Reports::Period

  def nonconformities_report
    @controller = params[:controller_name]
    final = params[:final]
    @title = t("#{@controller}_committee_report.nonconformities_report_title")
    @from_date, @to_date = *make_date_range(params[:nonconformities_report])
    @periods = periods_for_interval
    @column_order = ['business_unit_report_name', 'score',
      'nonconformities']
    @filters = []
    @notorious_reviews = {}
    conclusion_reviews = ConclusionFinalReview.list_all_by_date(
      @from_date, @to_date
    )

    if params[:nonconformities_report]
      unless params[:nonconformities_report][:business_unit_type].blank?
        @selected_business_unit = BusinessUnitType.find(
          params[:nonconformities_report][:business_unit_type])
        conclusion_reviews = conclusion_reviews.by_business_unit_type(
          @selected_business_unit.id)
        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = " +
          "\"#{@selected_business_unit.name.strip}\""
      end

      unless params[:nonconformities_report][:business_unit].blank?
        business_units =
          params[:nonconformities_report][:business_unit].split(
            SPLIT_AND_TERMS_REGEXP
          ).uniq.map(&:strip)

        unless business_units.empty?
          conclusion_reviews = conclusion_reviews.by_business_unit_names(
            *business_units)
          @filters << "<b>#{BusinessUnit.model_name.human}</b> = " +
            "\"#{params[:nonconformities_report][:business_unit].strip}\""
        end
      end
    end

    @periods.each do |period|
      BusinessUnitType.list.each do |but|
        columns = {
          'business_unit_report_name' => [but.business_unit_label, 15],
          'score' => [Review.human_attribute_name(:score), 15],
          'nonconformities' =>
            [t("#{@controller}_committee_report.nonconformities_report_title"), 70]
        }
        column_data = []
        name = but.name
        conclusion_review_per_unit_type =
          conclusion_reviews.for_period(period).by_business_unit_type(but.id)

        conclusion_review_per_unit_type.each do |c_r|
          nonconformities = []
          review_nonconformities = final ?  c_r.review.final_nonconformities : c_r.review.nonconformities

          review_nonconformities.each do |nc|
            audited = nc.users.select(&:audited?).map do |u|
              nc.process_owners.include?(u) ?
                "<b>#{u.full_name} (#{FindingUserAssignment.human_attribute_name(:process_owner)})</b>" :
                u.full_name
            end

            nonconformities << [
              "<b>#{Review.model_name.human}</b>: #{nc.review.to_s}",
              "<b>#{Nonconformity.human_attribute_name(:review_code)}</b>: #{nc.review_code}",
              "<b>#{Nonconformity.human_attribute_name(:title)}</b>: #{nc.title}",
              "<b>#{Nonconformity.human_attribute_name(:state)}</b>: #{nc.state_text}",
              "<b>#{Nonconformity.human_attribute_name(:risk)}</b>: #{nc.risk_text}",
              ("<b>#{Nonconformity.human_attribute_name(:follow_up_date)}</b>: #{l(nc.follow_up_date, :format => :long)}" if nc.follow_up_date),
              ("<b>#{Nonconformity.human_attribute_name(:origination_date)}</b>: #{l(nc.origination_date, :format => :long)}" if nc.origination_date),
              "<b>#{I18n.t('finding.audited', :count => audited.size)}</b>: #{audited.join('; ')}",
              "<b>#{Nonconformity.human_attribute_name(:description)}</b>: #{nc.description}",
              "<b>#{Nonconformity.human_attribute_name(:audit_comments)}</b>: #{nc.audit_comments}",
              "<b>#{Nonconformity.human_attribute_name(:answer)}</b>: #{nc.answer}"
            ].compact.join("\n")
          end

          unless nonconformities.blank?
            column_data << [
              c_r.review.business_unit.name,
              c_r.review.reload.score_text,
              nonconformities
            ]
          end
        end

        unless column_data.blank?
          @notorious_reviews[period] ||= []
          @notorious_reviews[period] << {
            :name => name,
            :external => but.external,
            :columns => columns,
            :column_data => column_data
          }
        end
      end
    end
  end

  def create_nonconformities_report
    self.nonconformities_report

    pdf = init_pdf(params[:report_title], params[:report_subtitle])

    add_pdf_description(pdf, @controller, @from_date, @to_date)

    @periods.each do |period|
      unless @notorious_reviews[period].blank?
        add_period_title(pdf, period)

        @notorious_reviews[period].each do |data|
          columns = data[:columns]
          column_data, column_headers = [], []

          @column_order.each do |order|
            column_headers << columns[order].first
          end
          if !data[:external] && !@internal_title_showed
            title = t("#{@controller}_committee_report.nonconformities_report.internal_audit_nonconformities")
            @internal_title_showed = true
          elsif data[:external] && !@external_title_showed
            title = t("#{@controller}_committee_report.nonconformities_report.external_audit_nonconformities")
            @external_title_showed = true
          end

          if title
            pdf.move_down PDF_FONT_SIZE * 2
            pdf.add_title title, (PDF_FONT_SIZE * 1.25).round, :center
          end

          pdf.add_subtitle data[:name], PDF_FONT_SIZE, PDF_FONT_SIZE

          unless data[:column_data].blank?
            pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
              data[:column_data].each do |col_data|
                column_headers.each_with_index do |header, i|
                  if col_data[i].kind_of?(Array)
                    pdf.text "<b>#{header.upcase}</b>:", :inline_format => true
                    pdf.move_down PDF_FONT_SIZE
                    col_data[i].each do |data|
                      pdf.text data, :inline_format => true
                      pdf.move_down PDF_FONT_SIZE
                    end
                    pdf.move_down PDF_FONT_SIZE
                  else
                    pdf.text "<b>#{header.upcase}</b>: #{col_data[i]}", :inline_format => true
                    pdf.move_down PDF_FONT_SIZE
                  end
                end
              end
            end
          else
            pdf.text(
              t("#{@controller}_committee_report.nonconformities_report.without_audits_in_the_period"),
              :style => :italic
            )
          end
        end
      end
    end

    add_pdf_filters(pdf, @controller, @filters) if @filters.present?

    save_pdf(pdf, @controller, @from_date, @to_date, 'nonconformities_report')

    redirect_to_pdf(@controller, @from_date, @to_date, 'nonconformities_report')
  end
end
