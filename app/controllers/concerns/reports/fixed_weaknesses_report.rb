module Reports::FixedWeaknessesReport                                                                                                
  extend ActiveSupport::Concern

  include Reports::Pdf
  include Reports::Period

  def fixed_weaknesses_report
    @controller = params[:controller_name]
    final = params[:final]
    @title = t("#{@controller}_committee_report.fixed_weaknesses_report_title")
    @from_date, @to_date = *make_date_range(params[:fixed_weaknesses_report])
    @periods = periods_by_solution_date_for_interval
    @column_order = ['business_unit_report_name', 'score', 'fixed_weaknesses']
    @filters = []
    @reviews = {}
    conclusion_reviews = final ? ConclusionFinalReview.list_all_by_final_solution_date(
      @from_date, @to_date) :
      ConclusionFinalReview.list_all_by_solution_date(                                               
      @from_date, @to_date)  

    if params[:fixed_weaknesses_report]
      risk = params[:fixed_weaknesses_report][:risk] 

      unless params[:fixed_weaknesses_report][:business_unit_type].blank?
        @selected_business_unit = BusinessUnitType.find(
          params[:fixed_weaknesses_report][:business_unit_type])
        conclusion_reviews = conclusion_reviews.by_business_unit_type(
          @selected_business_unit.id)
        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = " +
          "\"#{@selected_business_unit.name.strip}\""
      end

      unless params[:fixed_weaknesses_report][:business_unit].blank?
        business_units = params[:fixed_weaknesses_report][:business_unit].split(
          SPLIT_AND_TERMS_REGEXP
        ).uniq.map(&:strip)

        unless business_units.empty?
          conclusion_reviews = conclusion_reviews.by_business_unit_names(
            *business_units)
          @filters << "<b>#{BusinessUnit.model_name.human}</b> = " +
            "\"#{params[:fixed_weaknesses_report][:business_unit].strip}\""
        end
      end
    end

    risk ||= 1

    @periods.each do |period|
      BusinessUnitType.list.each do |but|
        columns = {
          'business_unit_report_name' => [but.business_unit_label, 15],
          'score' => [Review.human_attribute_name(:score), 15],
          'fixed_weaknesses' =>
            [t("#{@controller}_committee_report.fixed_weaknesses"), 70]
        }
        column_data = []
        name = but.name
        conclusion_review_per_unit_type =
          conclusion_reviews.for_period(period).with_business_unit_type(but.id)

        conclusion_review_per_unit_type.each do |c_r|
          fixed_weaknesses = []
          weaknesses = final ? c_r.review.final_weaknesses : c_r.review.weaknesses  
          weaknesses_by_risk = weaknesses.with_solution_date_between(
            @from_date, @to_date).by_risk(risk)

          weaknesses_by_risk.each do |w|
            audited = w.users.select(&:audited?).map do |u|
              w.process_owners.include?(u) ?
                "<b>#{u.full_name} (#{FindingUserAssignment.human_attribute_name(:process_owner)})</b>" :
                u.full_name
            end

            fixed_weaknesses << [
              "\n<b>#{Review.model_name.human}</b>: #{w.review.to_s}",
              "<b>#{Weakness.human_attribute_name(:review_code)}</b>: #{w.review_code}",
              "<b>#{Weakness.human_attribute_name(:state)}</b>: #{w.state_text}",
              "<b>#{Weakness.human_attribute_name(:risk)}</b>: #{w.risk_text}",
              "<b>#{Weakness.human_attribute_name(:solution_date)}</b>: #{l(w.solution_date, :format => :long)}",
              ("<b>#{Weakness.human_attribute_name(:origination_date)}</b>: #{l(w.origination_date, :format => :long)}" if w.origination_date),
              "<b>#{I18n.t('finding.audited', :count => audited.size)}</b>: #{audited.join('; ')}",
              "<b>#{Weakness.human_attribute_name(:description)}</b>: #{w.description}",
              "<b>#{Weakness.human_attribute_name(:audit_comments)}</b>: #{w.audit_comments}",
              "<b>#{Weakness.human_attribute_name(:answer)}</b>: #{w.answer}"
            ].compact.join("\n")
          end

          unless fixed_weaknesses.blank?
            column_data << [
              c_r.review.business_unit.name,
              c_r.review.reload.score_text,
              fixed_weaknesses
            ]
          end
        end

        unless column_data.blank?
          @reviews[period] ||= []
          @reviews[period] << {
            :name => name,
            :external => but.external,
            :columns => columns,
            :column_data => column_data
          }
        end
      end
    end
  end

  # Crea un PDF con las observaciones solucionadas para un determinado rango de
  # fechas
  #
  # * POST /conclusion_committee_reports/create_fixed_weaknesses_report
  def create_fixed_weaknesses_report
    self.fixed_weaknesses_report

    pdf = init_pdf(@auth_organization, params[:report_title], params[:report_subtitle])

    add_pdf_description(pdf, @controller, @from_date, @to_date)

    @periods.each do |period|
      unless @reviews[period].blank?
        add_period_title(pdf, period, :justify)

        @reviews[period].each do |data|
          columns = data[:columns]
          column_data, column_headers = [], []

          @column_order.each do |column|
            column_headers << columns[column].first
          end

          if !data[:external] && !@internal_title_showed
            title = t("#{@controller}_committee_report.fixed_weaknesses_report.internal_audit_weaknesses")
            @internal_title_showed = true
          elsif data[:external] && !@external_title_showed
            title = t("#{@controller}_committee_report.fixed_weaknesses_report.external_audit_weaknesses")
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
                  if col_data[i].kind_of? Array
                    col_data[i].each do |data|
                      pdf.text data, :inline_format => true
                    end
                  else
                    pdf.text "<b>#{header.upcase}</b>: #{col_data[i]}", :inline_format => true
                  end
                end
              end
            end
          else
            pdf.text(
              t("#{@controller}_committee_report.fixed_weaknesses_report.without_audits_in_the_period"),
              :style => :italic)
          end
        end
      end
    end

    add_pdf_filters(pdf, @controllers, @filters) if @filters.present?

    save_pdf(pdf, @controller, @from_date, @to_date, 'fixed_weaknesses_report')

    redirect_to_pdf(@controller, @from_date, @to_date, 'fixed_weaknesses_report')
  end
end
