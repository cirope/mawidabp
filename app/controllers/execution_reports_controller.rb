class ExecutionReportsController < ApplicationController
  before_action :auth, :load_privileges, :check_privileges

  # Muestra una lista con los reportes disponibles
  #
  # * GET /execution_reports
  def index
    @title = t 'execution_reports.index_title'

    respond_to do |format|
      format.html
    end
  end

  # Crea un PDF con una síntesis de las observaciones para un determinado rango
  # de fechas
  #
  # * GET /execution_reports/detailed_management_report
  def detailed_management_report
    @title = t 'execution_reports.detailed_management_report_title'
    @from_date, @to_date = *make_date_range(params[:detailed_management_report])
    @sqm = @auth_organization.kind.eql? 'quality_management'
    @column_order = ['business_unit_report_name', 'review', 'process_control',
      'weaknesses_count']
    @column_order << (@sqm ? 'nonconformities_count' : 'oportunities_count')
    @risk_levels = []
    @audits_by_period = []
    audits_by_business_unit = []

    raw_reviews = Review.includes(
      {control_objective_items: :control_objective},
      {plan_item: :business_unit}
    ).list_all_without_final_review_by_date(@from_date, @to_date)

    raw_reviews.group_by(&:period).each do |period, reviews|
      audits_by_business_unit = []

      BusinessUnitType.list.each do |but|
        columns = {
          'business_unit_report_name' => [but.business_unit_label, 15],
          'review' => [Review.model_name.human, 16],
          'process_control' =>
            ["#{BestPractice.human_attribute_name(:process_controls)}", 45],
          'weaknesses_count' => ["#{t('review.weaknesses_count')} (1)", 12]
        }
        if @sqm
          columns['nonconformities_count'] = ["#{t('review.nonconformities_count')} (2)", 12]
        else
          columns['oportunities_count'] = ["#{t('review.oportunities_count')} (2)", 12]
        end

        column_data = []
        name = but.name

        reviews.each do |r|
          if r.business_unit.business_unit_type_id == but.id
            process_controls = []
            weaknesses_count = {}

            r.control_objective_items.each do |coi|
              unless process_controls.include?(coi.process_control.name)
                process_controls << coi.process_control.name
              end
            end

            r.weaknesses.each do |w|
              @risk_levels |= w.class.risks.sort{|r1, r2| r2[1] <=> r1[1]}.map(&:first)

              weaknesses_count[w.risk_text] ||= 0
              weaknesses_count[w.risk_text] += 1
            end

            weaknesses_count_text = weaknesses_count.values.sum == 0 ?
              t('execution_reports.detailed_management_report.without_weaknesses') :
              @risk_levels.map { |risk| "#{risk}: #{weaknesses_count[risk] || 0}"}
            if @sqm
              nonconformities_count_text = r.nonconformities.count > 0 ?
                r.nonconformities.count.to_s :
                t('execution_reports.detailed_management_report.without_nonconformities')
            else
              oportunities_count_text = r.oportunities.count > 0 ?
                r.oportunities.count.to_s :
                t('execution_reports.detailed_management_report.without_oportunities')
            end
            column_data << [
              r.business_unit.name,
              r.to_s,
              process_controls,
              @risk_levels.blank? ?
                t('execution_reports.detailed_management_report.without_weaknesses') :
                weaknesses_count_text,
              @sqm ? nonconformities_count_text : oportunities_count_text
            ]
          end
        end

        audits_by_business_unit << {
          name: name,
          external: but.external,
          columns: columns,
          column_data: column_data
        }
      end

      @audits_by_period << {
        period: period,
        audits_by_business_unit: audits_by_business_unit
      }
    end
  end

  def create_detailed_management_report
    self.detailed_management_report

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.text '<i>%s</i>' %
      t('execution_reports.detailed_management_report.clarification'),
      font_size: PDF_FONT_SIZE, inline_format: true

    pdf.move_down PDF_FONT_SIZE

    pdf.add_description_item(t('execution_reports.period.title'),
      t('execution_reports.period.range',
        from_date: l(@from_date, format: :long),
        to_date: l(@to_date, format: :long)))

    @audits_by_period.each do |audit_by_period|
      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title "#{Period.model_name.human}: #{audit_by_period[:period].inspect}",
        (PDF_FONT_SIZE * 1.25).round, :left

      audit_by_period[:audits_by_business_unit].each do |data|
        columns = data[:columns]
        column_data, column_headers, column_widths = [], [], []

        @column_order.each do |col_name|
          column_headers << "<b>#{columns[col_name].first}</b>"
          column_widths << pdf.percent_width(columns[col_name].last)
        end

        if !data[:external] && !@internal_title_showed
          title = t 'execution_reports.detailed_management_report.internal_audit_weaknesses'
          @internal_title_showed = true
        elsif data[:external] && !@external_title_showed
          title = t 'execution_reports.detailed_management_report.external_audit_weaknesses'
          @external_title_showed = true
        end

        if title
          pdf.move_down PDF_FONT_SIZE * 2
          pdf.add_title title, (PDF_FONT_SIZE * 1.25).round, :center
        end

        pdf.add_subtitle data[:name], PDF_FONT_SIZE, PDF_FONT_SIZE

        data[:column_data].each do |row|
          new_row = []

          row.each do |column_content|
            new_row << (column_content.kind_of?(Array) ?
              column_content.map {|l| "  • #{l}"}.join("\n") :
              column_content)
          end

          column_data << new_row
        end

        unless column_data.blank?
          pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
            table_options = pdf.default_table_options(column_widths)

            pdf.table(column_data.insert(0, column_headers), table_options) do
              row(0).style(
                background_color: 'cccccc',
                padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
              )
            end
          end
        else
          pdf.text(
            t('execution_reports.detailed_management_report.without_audits_in_the_period'),
            style: :italic)
        end
      end
    end

    if @audits_by_period.empty?
      pdf.move_down PDF_FONT_SIZE
      pdf.text(
        t('execution_reports.detailed_management_report.without_audits_in_the_interval'))
    end

    pdf.move_down PDF_FONT_SIZE
    if @sqm
      pdf.text t('execution_reports.detailed_management_report.sqm_references'),
        font_size: (PDF_FONT_SIZE * 0.75).round, justification: :full
    else
      pdf.text t('execution_reports.detailed_management_report.references',
        risk_types: @risk_levels.to_sentence),
        font_size: (PDF_FONT_SIZE * 0.75).round, justification: :full
    end
    pdf.custom_save_as(
      t('execution_reports.detailed_management_report.pdf_name',
        from_date: @from_date.to_formatted_s(:db),
        to_date: @to_date.to_formatted_s(:db)),
      'detailed_management_report', 0)

    redirect_to Prawn::Document.relative_path(
      t('execution_reports.detailed_management_report.pdf_name',
        from_date: @from_date.to_formatted_s(:db),
        to_date: @to_date.to_formatted_s(:db)),
      'detailed_management_report', 0)
  end

  def weaknesses_by_state
    @title = t 'execution_reports.weaknesses_by_state_title'
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_state])
    @audit_types = [:internal, :external]
    @sqm = @auth_organization.kind.eql? 'quality_management'
    @counts = []
    @status = Finding::STATUS.except(:repeated, :revoked).sort do |s1, s2|
      s1.last <=> s2.last
    end
    @reviews = Review.list_all_without_final_review_by_date @from_date, @to_date

    @reviews.group_by(&:period).each do |period, reviews|
      count_for_period = {}

      @audit_types.each do |audit_type|
        reviews.select(&:"#{audit_type}_audit?").each do |review|
          count_for_period[audit_type] ||= {}
          count_for_period[audit_type][review] ||= {}
          count_for_period[audit_type][review][:weaknesses] =
            review.weaknesses.group(:state).count
          count_for_period[audit_type][review][:oportunities] =
            review.oportunities.group(:state).count
          if @sqm
            count_for_period[audit_type][review][:nonconformities] =
              review.nonconformities.group(:state).count
            count_for_period[audit_type][review][:potential_nonconformities] =
              review.potential_nonconformities.group(:state).count
          end
        end
      end

      @counts << { period: period, counts: count_for_period }
    end
  end

  def create_weaknesses_by_state
    self.weaknesses_by_state

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.text '<i>%s</i>' %
      t('execution_reports.weaknesses_by_state.clarification'),
        font_size: PDF_FONT_SIZE, inline_format: true

    pdf.move_down PDF_FONT_SIZE

    pdf.add_description_item(
      t('execution_reports.period.title'),
      t('execution_reports.period.range',
        from_date: l(@from_date, format: :long),
        to_date: l(@to_date, format: :long)))

    @counts.each do |count_data|
      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_title "#{Period.model_name.human}: #{count_data[:period].inspect}",
        (PDF_FONT_SIZE * 1.25).round, :justify

      @audit_types.each do |type|
        pdf.move_down PDF_FONT_SIZE * 2

        pdf.add_title t("execution_reports.findings_type_#{type}"),
          (PDF_FONT_SIZE * 1.25).round, :center

        if count_data[:counts][type]
          count_data[:counts][type].each do |review, counts|
            weaknesses_count = counts[:weaknesses]
            oportunities_count = counts[:oportunities]
            total_weaknesses = weaknesses_count.values.sum
            total_oportunities = oportunities_count.values.sum
            if @sqm
              nonconformities_count = counts[:nonconformities]
              potential_nonconformities_count = counts[:potential_nonconformities]
              total_nonconformities = nonconformities_count.values.sum
              total_potential_nonconformities = potential_nonconformities_count.values.sum
            end

            pdf.text "\n<b>#{Review.model_name.human}</b>: #{review}\n\n",
              font_size: PDF_FONT_SIZE, inline_format: true

            totals = total_weaknesses + total_oportunities
            totals+= (total_nonconformities + total_potential_nonconformities) if @sqm

            unless totals == 0
              columns = [
                [Finding.human_attribute_name('state'), 20],
                [
                  t('execution_reports.weaknesses_by_state.weaknesses_column'),
                  20]
              ]
              column_data, column_headers, column_widths = [], [], []

              if type == :internal && !@sqm
                columns << [
                  t('execution_reports.weaknesses_by_state.oportunities_column'),
                  20]
              elsif type == :internal && @sqm
                columns << [
                  t('execution_reports.weaknesses_by_state.oportunities_column'),
                  20]
                columns << [
                  t('execution_reports.weaknesses_by_state.nonconformities_column'),
                  20]
                columns << [
                  t('execution_reports.weaknesses_by_state.potential_nonconformities_column'),
                  20]
              end

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
                  t("finding.status_#{state.first}"),
                  "#{w_count} (#{'%.2f' % weaknesses_percentage.round(2)}%)"
                ]

                if type == :internal && !@sqm
                  column_data.last << "#{o_count} (#{'%.2f' % oportunities_percentage.round(2)}%)"

                elsif type == :internal && @sqm
                  column_data.last << "#{o_count} (#{'%.2f' % oportunities_percentage.round(2)}%)"

                  nc_count = nonconformities_count[state.last] || 0
                  pnc_count = potential_nonconformities_count[state.last] || 0
                  nonconformities_percentage = total_nonconformities > 0 ? nc_count.to_f / total_nonconformities * 100 : 0.0
                  potential_nonconformities_percentage = total_potential_nonconformities > 0 ? pnc_count.to_f / total_potential_nonconformities * 100 : 0.0

                  column_data.last << "#{nc_count} (#{'%.2f' % nonconformities_percentage.round(2)}%)"
                  column_data.last << "#{pnc_count} (#{'%.2f' % potential_nonconformities_percentage.round(2)}%)"
                end
              end

              column_data << [
                "<b>#{t('execution_reports.weaknesses_by_state.total')}</b>",
                "<b>#{total_weaknesses}</b>"
              ]

              if type == :internal && !@sqm
                column_data.last << "<b>#{total_oportunities}</b>"

              elsif type == :internal && @sqm
                column_data.last << "<b>#{total_oportunities}</b>"
                column_data.last << "<b>#{total_nonconformities}</b>"
                column_data.last << "<b>#{total_potential_nonconformities}</b>"
              end

              unless column_data.blank?
                pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
                  table_options = pdf.default_table_options(column_widths)

                  pdf.table(column_data.insert(0, column_headers), table_options) do
                    row(0).style(
                      background_color: 'cccccc',
                      padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
                    )
                  end
                end
              end
            else
              pdf.text t('execution_reports.without_findings'),
                font_size: PDF_FONT_SIZE, style: :italic
              pdf.move_down PDF_FONT_SIZE
            end
          end
        else
          pdf.text t('execution_reports.without_weaknesses'),
            font_size: PDF_FONT_SIZE, style: :italic
        end
      end
    end

    if @counts.empty?
      pdf.move_down PDF_FONT_SIZE
      pdf.text t('execution_reports.without_weaknesses_in_the_interval'),
        font_size: PDF_FONT_SIZE
    end

    pdf.custom_save_as(
      t('execution_reports.weaknesses_by_state.pdf_name',
        from_date: @from_date.to_formatted_s(:db),
        to_date: @to_date.to_formatted_s(:db)),
      'execution_weaknesses_by_state', 0)

    redirect_to Prawn::Document.relative_path(
      t('execution_reports.weaknesses_by_state.pdf_name',
        from_date: @from_date.to_formatted_s(:db),
        to_date: @to_date.to_formatted_s(:db)),
      'execution_weaknesses_by_state', 0)
  end

  private
    def load_privileges
      @action_privileges.update(
        detailed_management_report: :read,
        create_detailed_management_report: :read,
        weaknesses_by_state: :read,
        create_weaknesses_by_state: :read
      )
    end
end
