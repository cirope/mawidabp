class ExecutionReportsController < ApplicationController
  before_filter :auth, :load_privileges, :check_privileges
  hide_action :load_privileges
  
  # Muestra una lista con los reportes disponibles
  #
  # * GET /execution_reports
  def index
    @title = t :'execution_reports.index_title'

    respond_to do |format|
      format.html
    end
  end

  # Crea un PDF con una síntesis de las observaciones para un determinado rango
  # de fechas
  #
  # * GET /execution_reports/detailed_management_report
  # * POST /execution_reports/detailed_management_report
  def detailed_management_report
    @title = t :'execution_reports.detailed_management_report_title'
    @from_date, @to_date = *make_date_range(params[:detailed_management_report])
    @column_order = ['business_unit_report_name', 'review', 'process_control',
      'weaknesses_count', 'oportunities_count']
    @risk_levels = []
    @audits_by_business_unit = []
    reviews = Review.list_all_without_final_review_by_date @from_date, @to_date

    BusinessUnit::TYPES.sort {|t1, t2| t1[1] <=> t2[1]}.each do |type, value|
      columns = {'business_unit_report_name' =>
          [t("organization.business_unit_#{type}.report_name"), 15],
        'review' => [Review.human_name, 16],
        'process_control' =>
          ["#{BestPractice.human_attribute_name('process_controls')}", 45],
        'weaknesses_count' => ["#{t(:'review.weaknesses_count')} (1)", 12],
        'oportunities_count' => ["#{t(:'review.oportunities_count')} (2)", 12]}
      column_data = []
      name = t "organization.business_unit_#{type}.type"

      reviews.each do |r|
        if r.business_unit.business_unit_type == value
          process_controls = []
          weaknesses_count = {}

          r.control_objective_items.each do |coi|
            unless process_controls.include?(coi.process_control.name)
              process_controls << coi.process_control.name
            end
          end

          r.weaknesses.each do |w|
            @risk_levels |= parameter_in(@auth_organization.id,
              :admin_finding_risk_levels, w.created_at).
              sort{|r1, r2| r2[1] <=> r1[1]}.map(&:first)

            weaknesses_count[w.risk_text] ||= 0
            weaknesses_count[w.risk_text] += 1
          end

          weaknesses_count_text = weaknesses_count.values.sum == 0 ?
            t(:'execution_reports.detailed_management_report.without_weaknesses') :
            @risk_levels.map { |risk| "#{risk}: #{weaknesses_count[risk] || 0}"}
          oportunities_count_text = r.oportunities.count > 0 ?
            r.oportunities.count.to_s :
            t(:'execution_reports.detailed_management_report.without_oportunities')

          column_data << {
            'business_unit_report_name' => r.business_unit.name,
            'review' => r.to_s,
            'process_control' => process_controls,
            'weaknesses_count' => @risk_levels.blank? ?
              t(:'execution_reports.detailed_management_report.without_weaknesses') :
              weaknesses_count_text,
            'oportunities_count' => oportunities_count_text
          }
        end
      end

      @audits_by_business_unit << {
        :name => name,
        :value => value,
        :columns => columns,
        :column_data => column_data
      }
    end

    unless params[:download].blank?
      pdf = PDF::Writer.create_generic_pdf :landscape

      pdf.add_generic_report_header @auth_organization

      pdf.add_title t(:'execution_reports.detailed_management_report.title'),
        12, :center

      pdf.move_pointer 12

      pdf.add_title t(:'execution_reports.detailed_management_report.subtitle'),
        12, :center

      pdf.move_pointer 12

      pdf.text '<i>%s</i>' %
        t(:'execution_reports.detailed_management_report.clarification'),
        :font_size => 10

      pdf.move_pointer 12

      pdf.add_description_item(t(:'execution_reports.period.title'),
        t(:'execution_reports.period.range',
          :from_date => l(@from_date, :format => :long),
          :to_date => l(@to_date, :format => :long)))

      @audits_by_business_unit.each do |data|
        columns = data[:columns]
        column_data = []

        @column_order.each do |col_name|
          columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |column|
            column.heading = columns[col_name].first
            column.width = pdf.percent_width columns[col_name].last
          end
        end

        if data[:value] == BusinessUnit::INTERNAL_TYPES.values.sort.first
          title = t :'execution_reports.detailed_management_report.internal_audit_weaknesses'
        elsif data[:value] == BusinessUnit::EXTERNAL_TYPES.values.sort.first
          title = t :'execution_reports.detailed_management_report.external_audit_weaknesses'
        end

        if title
          pdf.move_pointer 24
          pdf.add_title title, 14, :center
        end

        pdf.add_subtitle data[:name], 12, 12

        data[:column_data].each do |row|
          new_row = {}

          row.each do |column_name, column_content|
            new_row[column_name] = column_content.kind_of?(Array) ?
              column_content.map {|l| "  <C:bullet /> #{l}"}.join("\n").to_iso :
              column_content.to_iso
          end

          column_data << new_row
        end

        unless column_data.blank?
          PDF::SimpleTable.new do |table|
            table.width = pdf.page_usable_width
            table.columns = columns
            table.data = column_data
            table.column_order = @column_order
            table.split_rows = true
            table.font_size = 8
            table.shade_color = Color::RGB::Grey70
            table.shade_heading_color = Color::RGB::Grey50
            table.heading_font_size = 10
            table.shade_headings = true
            table.position = :left
            table.orientation = :right
            table.render_on pdf
          end
        else
          pdf.text(
            t(:'execution_reports.detailed_management_report.without_audits_in_the_period'))
        end
      end

      pdf.move_pointer 12
      pdf.text t(:'execution_reports.detailed_management_report.references',
        :risk_types => @risk_levels.to_sentence), :font_size => 8,
        :justification => :full

      pdf.custom_save_as(
        t(:'execution_reports.detailed_management_report.pdf_name',
          :from_date => @from_date.to_formatted_s(:db),
          :to_date => @to_date.to_formatted_s(:db)),
        'detailed_management_report', 0)

      redirect_to PDF::Writer.relative_path(
        t(:'execution_reports.detailed_management_report.pdf_name',
          :from_date => @from_date.to_formatted_s(:db),
          :to_date => @to_date.to_formatted_s(:db)),
        'detailed_management_report', 0)
    end
  end

  def weaknesses_by_state
    @title = t :'execution_reports.weaknesses_by_state_title'
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_state])
    @audit_types = [:internal, :external, :bcra]
    @counts = {}
    @status = Finding::STATUS.sort { |s1, s2| s1.last <=> s2.last }
    @reviews = Review.list_all_without_final_review_by_date(
        @from_date, @to_date)

    @audit_types.each do |audit_type|
      @reviews.send("#{audit_type}_audit").each do |review|
        @counts[audit_type] ||= {}
        @counts[audit_type][review] ||= {}
        @counts[audit_type][review][:weaknesses] =
          review.weaknesses.count(:group => :state)
        @counts[audit_type][review][:oportunities] =
          review.oportunities.count(:group => :state)
      end
    end


    unless params[:download].blank?
      pdf = PDF::Writer.create_generic_pdf :landscape

      pdf.add_generic_report_header @auth_organization

      pdf.add_title t(:'execution_reports.weaknesses_by_state.title'),
        12, :center

      pdf.move_pointer 12

      pdf.text '<i>%s</i>' %
        t(:'execution_reports.weaknesses_by_state.clarification'),
          :font_size => 10

      pdf.move_pointer 12

      pdf.add_description_item(
        t(:'execution_reports.period.title'),
        t(:'execution_reports.period.range',
          :from_date => l(@from_date, :format => :long),
          :to_date => l(@to_date, :format => :long)))

      @audit_types.each do |type|
        pdf.move_pointer 24

        pdf.add_title t("execution_reports.findings_type_#{type}"), 14, :center

        if @counts[type]
          @counts[type].each do |review, counts|
            weaknesses_count = counts[:weaknesses]
            oportunities_count = counts[:oportunities]
            total_weaknesses = weaknesses_count.values.sum
            total_oportunities = oportunities_count.values.sum

            pdf.text "\n<b>#{Review.human_name}</b>: #{review}\n\n",
              :font_size => 12

            unless (total_weaknesses + total_oportunities) == 0
              columns = {
                'state' => [Finding.human_attribute_name('state'), 30],
                'weaknesses_count' => [
                  t(:'execution_reports.weaknesses_by_state.weaknesses_column'),
                  type == :internal ? 35 : 70]
              }
              column_data = []

              if type == :internal
                columns['oportunities_count'] = [
                  t(:'execution_reports.weaknesses_by_state.oportunities_column'),
                  35]
              end

              columns.each do |col_name, col_data|
                columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
                  c.heading = col_data.first
                  c.width = pdf.percent_width col_data.last
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
                  'state' => t("finding.status_#{state.first}").to_iso,
                  'weaknesses_count' =>
                    "#{w_count} (#{'%.2f' % weaknesses_percentage.round(2)}%)",
                  'oportunities_count' =>
                    "#{o_count} (#{'%.2f' % oportunities_percentage.round(2)}%)",
                }
              end

              column_data << {
                'state' =>
                  "<b>#{t(:'execution_reports.weaknesses_by_state.total')}</b>".to_iso,
                'weaknesses_count' => "<b>#{total_weaknesses}</b>",
                'oportunities_count' => "<b>#{total_oportunities}</b>"
              }

              unless column_data.blank?
                PDF::SimpleTable.new do |table|
                  table.width = pdf.page_usable_width
                  table.columns = columns
                  table.data = column_data
                  table.column_order = type == :internal ?
                    ['state', 'weaknesses_count', 'oportunities_count'] :
                    ['state', 'weaknesses_count']
                  table.split_rows = true
                  table.font_size = 12
                  table.row_gap = 6
                  table.shade_rows = :none
                  table.shade_heading_color = Color::RGB::Grey50
                  table.heading_font_size = 12
                  table.shade_headings = true
                  table.bold_headings = true
                  table.position = :left
                  table.orientation = :right
                  table.show_lines = :all
                  table.render_on pdf
                end
              end
            else
              pdf.text t(:'execution_reports.without_findings'),
                :font_size => 12
              pdf.move_pointer 12
            end
          end
        else
          pdf.text t(:'execution_reports.without_weaknesses'), :font_size => 12
        end
      end

      pdf.custom_save_as(
        t(:'execution_reports.weaknesses_by_state.pdf_name',
          :from_date => @from_date.to_formatted_s(:db),
          :to_date => @to_date.to_formatted_s(:db)),
        'execution_weaknesses_by_state', 0)

      redirect_to PDF::Writer.relative_path(
        t(:'execution_reports.weaknesses_by_state.pdf_name',
          :from_date => @from_date.to_formatted_s(:db),
          :to_date => @to_date.to_formatted_s(:db)),
        'execution_weaknesses_by_state', 0)
    end
  end

  private

  def load_privileges #:nodoc:
    @action_privileges.update({
      :detailed_management_report => :read,
      :weaknesses_by_state => :read
    })
  end
end