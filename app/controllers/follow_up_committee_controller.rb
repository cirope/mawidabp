require 'modules/follow_up_common_reports'

# =Controlador de comité
#
# Crea los reportes de comité
class FollowUpCommitteeController < ApplicationController
  include FollowUpCommonReports

  before_filter :auth, :load_privileges, :check_privileges
  hide_action :load_privileges, :get_organization, :add_weaknesses_synthesis_table,
    :being_implemented_resume_from_counts, :add_being_implemented_resume,
    :make_date_range, :get_weaknesses_synthesis_table_data

  # Muestra una lista con los reportes disponibles
  #
  # * GET /follow_up_committee
  def index
    @title = t :'follow_up_committee.index_title'

    respond_to do |format|
      format.html
    end
  end

  # Crea un PDF con una síntesis de las observaciones para un determinado rango
  # de fechas
  #
  # * GET /follow_up_committee/synthesis_report
  def synthesis_report
    @title = t :'follow_up_committee.synthesis_report_title'
    @from_date, @to_date = *make_date_range(params[:synthesis_report])
    @periods = periods_for_interval
    @column_order = ['business_unit_report_name', 'review', 'score',
        'process_control', 'weaknesses_count', 'oportunities_count']
    @filters = []
    @risk_levels = []
    @audits_by_business_unit = {}
    conclusion_reviews = ConclusionFinalReview.list_all_by_date(@from_date,
      @to_date)

    if params[:synthesis_report]
      unless params[:synthesis_report][:business_unit_type].blank?
        @selected_business_unit = BusinessUnitType.find(
          params[:synthesis_report][:business_unit_type])
        conclusion_reviews = conclusion_reviews.by_business_unit_type(
          @selected_business_unit.id)
        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = " +
          "\"#{@selected_business_unit.name.strip}\""
      end

      unless params[:synthesis_report][:business_unit].blank?
        business_units = params[:synthesis_report][:business_unit].split(
          SPLIT_AND_TERMS_REGEXP).uniq.map(&:strip)

        unless business_units.empty?
          conclusion_reviews = conclusion_reviews.by_business_unit_names(
            *business_units)
          @filters << "<b>#{BusinessUnit.model_name.human}</b> = " +
            "\"#{params[:synthesis_report][:business_unit].strip}\""
        end
      end
    end

    business_unit_types = @selected_business_unit ?
      [@selected_business_unit] : BusinessUnitType.list

    @periods.each do |period|
      business_unit_types.each do |but|
        columns = {'business_unit_report_name' => [but.business_unit_label, 15],
          'review' => [Review.model_name.human, 16],
          'score' => ["#{Review.human_attribute_name(:score)} (1)", 15],
          'process_control' =>
            ["#{BestPractice.human_attribute_name(:process_controls)} (2)", 30],
          'weaknesses_count' => ["#{t(:'review.weaknesses_count')} (3)", 12],
          'oportunities_count' => ["#{t(:'review.oportunities_count')} (4)", 12]}
        column_data = []
        review_scores = []
        repeated_count = 0
        name = but.name

        conclusion_reviews.for_period(period).each do |c_r|
          if c_r.review.business_unit.business_unit_type_id == but.id
            process_controls = {}
            weaknesses_count = {}

            c_r.review.control_objective_items.each do |coi|
              process_controls[coi.process_control.name] ||= []
              process_controls[coi.process_control.name] << coi
            end

            process_controls.each do |pc, control_objective_items|
              coi_count = control_objective_items.inject(0.0) do |acc, coi|
                acc + (coi.relevance || 0)
              end
              total = control_objective_items.inject(0.0) do |acc, coi|
                acc + coi.effectiveness * (coi.relevance || 0)
              end

              process_controls[pc] = coi_count > 0 ?
                (total / coi_count.to_f).round : 100
            end

            c_r.review.weaknesses.each do |w|
              @risk_levels |= parameter_in(@auth_organization.id,
                :admin_finding_risk_levels, w.created_at).
                sort { |r1, r2| r2[1] <=> r1[1] }.map { |r| r.first }

              weaknesses_count[w.risk_text] ||= 0
              
              if w.repeated?
                repeated_count += 1
              else
                weaknesses_count[w.risk_text] += 1
              end
            end

            weaknesses_count_text = weaknesses_count.values.sum == 0 ?
              t(:'follow_up_committee.synthesis_report.without_weaknesses') :
              @risk_levels.map { |risk| "#{risk}: #{weaknesses_count[risk] || 0}"}
            process_control_text = process_controls.sort do |pc1, pc2|
              pc1[1] <=> pc2[1]
            end.map { |pc| "#{pc[0]} (#{'%.2f' % pc[1]}%)" }
            oportunities_count_text = c_r.review.oportunities.not_repeated.count > 0 ?
              c_r.review.oportunities.not_repeated.count.to_s :
              t(:'follow_up_committee.synthesis_report.without_oportunities')
            repeated_count += c_r.review.oportunities.repeated.count

            review_scores << c_r.review.score
            column_data << {
              'business_unit_report_name' => c_r.review.business_unit.name,
              'review' => c_r.review.to_s,
              'score' => c_r.review.score_text,
              'process_control' => process_control_text,
              'weaknesses_count' => @risk_levels.blank? ?
                t(:'follow_up_committee.synthesis_report.without_weaknesses') :
                weaknesses_count_text,
              'oportunities_count' => oportunities_count_text
            }
          end
        end

        @audits_by_business_unit[period] ||= []
        @audits_by_business_unit[period] << {
          :name => name,
          :external => but.external,
          :columns => columns,
          :column_data => column_data,
          :review_scores => review_scores,
          :repeated_count => repeated_count
        }
      end
    end
  end

  # Crea un PDF con una síntesis de las observaciones para un determinado rango
  # de fechas
  #
  # * POST /follow_up_committee/create_synthesis_report
  def create_synthesis_report
    self.synthesis_report

    pdf = PDF::Writer.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE

    pdf.add_description_item(
      t(:'follow_up_committee.period.title'),
      t(:'follow_up_committee.period.range',
        :from_date => I18n.l(@from_date, :format => :long),
        :to_date => I18n.l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :justify

      unless @selected_business_unit
        unless @audits_by_business_unit[period].blank?
          count = 0
          total = @audits_by_business_unit[period].inject(0) do |sum, data|
            scores = data[:review_scores]

            if scores.blank?
              sum
            else
              count += 1
              sum + (scores.sum.to_f / scores.size).round
            end
          end

          average_score = count > 0 ? (total.to_f / count).round : 100
        end

        pdf.move_pointer PDF_FONT_SIZE

        pdf.add_title(
          t(:'follow_up_committee.synthesis_report.organization_score',
            :score => average_score || 100), (PDF_FONT_SIZE * 1.5).round)

        pdf.move_pointer((PDF_FONT_SIZE * 0.75).round)

        pdf.text(
          t(:'follow_up_committee.synthesis_report.organization_score_note',
            :audit_types =>
              @audits_by_business_unit[period].map { |data|
                data[:name]
              }.to_sentence),
          :font_size => (PDF_FONT_SIZE * 0.75).round)
      end

      @audits_by_business_unit[period].each do |data|
        columns = data[:columns]
        column_data = []

        @column_order.each do |col_name|
          columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |column|
            column.heading = columns[col_name].first
            column.width = pdf.percent_width columns[col_name].last
          end
        end

        if !data[:external] && !@internal_title_showed
          title = t :'follow_up_committee.synthesis_report.internal_audit_weaknesses'
          @internal_title_showed = true
        elsif data[:external] && !@external_title_showed
          title = t :'follow_up_committee.synthesis_report.external_audit_weaknesses'
          @external_title_showed = true
        end

        if title
          pdf.move_pointer PDF_FONT_SIZE * 2
          pdf.add_title title, (PDF_FONT_SIZE * 1.25).round, :center
        end

        pdf.add_subtitle data[:name], PDF_FONT_SIZE, PDF_FONT_SIZE

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
            table.data = column_data.sort do |row1, row2|
              row1['score'].match(/(\d+)%/)[0].to_i <=>
                row2['score'].match(/(\d+)%/)[0].to_i
            end
            table.column_order = @column_order
            table.split_rows = true
            table.row_gap = (PDF_FONT_SIZE * 1.25).round
            table.font_size = (PDF_FONT_SIZE * 0.75).round
            table.shade_color = Color::RGB.from_percentage(95, 95, 95)
            table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
            table.heading_font_size = PDF_FONT_SIZE
            table.shade_headings = true
            table.position = :left
            table.orientation = :right
            table.render_on pdf
          end

          scores = data[:review_scores]

          unless scores.blank?
            title = t(:'follow_up_committee.synthesis_report.generic_score_average',
              :audit_type => data[:name])
            text = "<b>#{title}</b>: <i>#{(scores.sum.to_f / scores.size).round}%</i>"
          else
            text = t(:'conclusion_committee_report.synthesis_report.without_audits_in_the_period')
          end

          pdf.move_pointer PDF_FONT_SIZE

          pdf.text text, :font_size => PDF_FONT_SIZE
          
          if data[:repeated_count] > 0
            pdf.text(t(:'follow_up_committee.synthesis_report.repeated_count',
                :count => data[:repeated_count]), :font_size => PDF_FONT_SIZE)
          end
        else
          pdf.text t(:'follow_up_committee.synthesis_report.without_audits_in_the_period')
        end
      end
    end

    unless @filters.empty?
      pdf.move_pointer PDF_FONT_SIZE
      pdf.text t(:'follow_up_committee.applied_filters',
        :filters => @filters.to_sentence, :count => @filters.size),
        :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full
    end

    pdf.move_pointer PDF_FONT_SIZE
    pdf.text t(:'follow_up_committee.synthesis_report.references',
      :risk_types => @risk_levels.to_sentence),
      :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full

    pdf.custom_save_as(t(:'follow_up_committee.synthesis_report.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'synthesis_report', 0)

    redirect_to PDF::Writer.relative_path(
      t(:'follow_up_committee.synthesis_report.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'synthesis_report', 0)
  end

  # Crea un PDF con un análisis de costos para un determinado rango de fechas
  #
  # * GET /follow_up_committee/cost_analysis
  def cost_analysis
    @title = t :'follow_up_committee.cost_analysis_title'
    @from_date, @to_date = *make_date_range(params[:cost_analysis])
    @periods = periods_for_interval
    @column_order = [['business_unit', 20], ['project', 20], ['review', 10],
      ['audit_cost', 25], ['audited_cost', 25]]
    @weaknesses_data = {}
    @oportunities_data = {}

    @periods.each do |period|
      @weaknesses_data[period] ||= []
      @oportunities_data[period] ||= []
      total_weaknesses_audit_cost, total_weaknesses_audited_cost = 0, 0
      total_oportunities_audit_cost, total_oportunities_audited_cost = 0, 0
      weaknesses_by_review = Weakness.with_status_for_report.list_all_by_date(
        @from_date, @to_date, false).finals(false).for_period(period).group_by(
        &:review)
      oportunities_by_review = Oportunity.with_status_for_report.list_all_by_date(
        @from_date, @to_date, false).finals(false).for_period(period).group_by(
        &:review)

      unless weaknesses_by_review.blank?
        weaknesses_by_review.each do |review, weaknesses|
          audit_cost = weaknesses.inject(0) do |sum, weakness|
            sum + weakness.costs.audit.to_a.sum(&:cost)
          end
          audited_cost = weaknesses.inject(0) do |sum, weakness|
            sum + weakness.costs.audited.to_a.sum(&:cost)
          end

          total_weaknesses_audit_cost += audit_cost
          total_weaknesses_audited_cost += audited_cost
          @weaknesses_data[period] << {
            'business_unit' => review.plan_item.business_unit.name.to_iso,
            'project' => review.plan_item.project.to_iso,
            'review' => review.identification.to_iso,
            'audit_cost' => audit_cost.to_s,
            'audited_cost' => audited_cost.to_s
          }
        end

        @weaknesses_data[period] << {
          'business_unit' => '', 'project' => '', 'review' => '',
          'audit_cost' => "<b>#{total_weaknesses_audit_cost}</b>",
          'audited_cost' => "<b>#{total_weaknesses_audited_cost}</b>"
        }
      end

      unless oportunities_by_review.blank?
        oportunities_by_review.each do |review, oportunities|
          audit_cost = oportunities.inject(0) do |sum, oportunity|
            sum + oportunity.costs.audit.to_a.sum(&:cost)
          end
          audited_cost = oportunities.inject(0) do |sum, oportunity|
            sum + oportunity.costs.audited.to_a.sum(&:cost)
          end

          total_oportunities_audit_cost += audit_cost
          total_oportunities_audited_cost += audited_cost
          @oportunities_data[period] << {
            'business_unit' => review.plan_item.business_unit.name.to_iso,
            'project' => review.plan_item.project.to_iso,
            'review' => review.identification.to_iso,
            'audit_cost' => audit_cost.to_s,
            'audited_cost' => audited_cost.to_s
          }
        end

        @oportunities_data[period] << {
          'business_unit' => '', 'project' => '', 'review' => '',
          'audit_cost' => "<b>#{total_oportunities_audit_cost}</b>",
          'audited_cost' => "<b>#{total_oportunities_audited_cost}</b>"
        }
      end
    end
  end

  # Crea un PDF con un análisis de costos para un determinado rango de fechas
  #
  # * POST /follow_up_committee/create_cost_analysis
  def create_cost_analysis
    self.cost_analysis

    pdf = PDF::Writer.create_generic_pdf :landscape
    columns = {}

    @column_order.each do |col_name, col_width|
      columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |column|
        column.heading =
          t("follow_up_committee.cost_analysis.column_#{col_name}")
        column.width = pdf.percent_width col_width
      end
    end

    pdf.add_generic_report_header @auth_organization
    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE

    pdf.add_description_item(
      t(:'follow_up_committee.period.title'),
      t(:'follow_up_committee.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    pdf.move_pointer PDF_FONT_SIZE

    @periods.each do |period|
      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :justify
      pdf.move_pointer PDF_FONT_SIZE

      pdf.add_title "#{t(:'follow_up_committee.cost_analysis.weaknesses')}\n",
        PDF_FONT_SIZE, :center

      unless @weaknesses_data[period].blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = @weaknesses_data[period]
          table.column_order = @column_order.map(&:first)
          table.split_rows = true
          table.font_size = (PDF_FONT_SIZE * 0.75).round
          table.shade_color = Color::RGB.from_percentage(95, 95, 95)
          table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
          table.heading_font_size = PDF_FONT_SIZE
          table.shade_headings = true
          table.position = :left
          table.orientation = :right
          table.render_on pdf
        end
      else
        pdf.text t(:'follow_up_committee.cost_analysis.without_weaknesses'),
          :font_size => PDF_FONT_SIZE
      end

      pdf.move_pointer PDF_FONT_SIZE

      pdf.add_title "#{t(:'follow_up_committee.cost_analysis.oportunities')}\n",
        PDF_FONT_SIZE, :center

      unless @oportunities_data[period].blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = @oportunities_data[period]
          table.column_order = @column_order.map(&:first)
          table.split_rows = true
          table.font_size = (PDF_FONT_SIZE * 0.75)
          table.shade_color = Color::RGB.from_percentage(95, 95, 95)
          table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
          table.heading_font_size = PDF_FONT_SIZE
          table.shade_headings = true
          table.position = :left
          table.orientation = :right
          table.render_on pdf
        end
      else
        pdf.text t(:'follow_up_committee.cost_analysis.without_oportunities'),
          :font_size => PDF_FONT_SIZE
      end
    end

    pdf.custom_save_as(
      t(:'follow_up_committee.cost_analysis.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'follow_up_cost_analysis',
      0)

    redirect_to PDF::Writer.relative_path(
      t(:'follow_up_committee.cost_analysis.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'follow_up_cost_analysis',
      0)
  end

  # Crea un PDF con los informes más notorios para un determinado rango de
  # fechas
  #
  # * GET /conclusion_committee_reports/high_risk_weaknesses_report
  def high_risk_weaknesses_report
    @title = t :'conclusion_committee_report.high_risk_weaknesses_report_title'
    @from_date, @to_date = *make_date_range(params[:high_risk_weaknesses_report])
    @periods = periods_for_interval
    @column_order = ['business_unit_report_name', 'review', 'score',
      'high_risk_weaknesses']
    @filters = []
    @notorious_reviews = {}
    conclusion_reviews = ConclusionFinalReview.list_all_by_date(@from_date,
      @to_date).notorious(false)

    @periods.each do |period|
      BusinessUnitType.list.each do |but|
        columns = {
          'business_unit_report_name' => [but.business_unit_label, 15],
          'review' => [Review.model_name.human, 15],
          'score' => [Review.human_attribute_name(:score), 15],
          'high_risk_weaknesses' =>
            [t(:'conclusion_committee_report.high_risk_weaknesses'), 55]
        }
        column_data = []
        name = but.name
        conclusion_review_per_unit_type =
          conclusion_reviews.for_period(period).with_business_unit_type(but.id)

        conclusion_review_per_unit_type.each do |c_r|
          high_risk_weaknesses = []
          weaknesses =
            c_r.review.weaknesses.with_highest_risk.with_pending_status

          weaknesses.each do |w|
            audited = w.users.select(&:audited?).map do |u|
              w.process_owners.include?(u) ?
                "<b>#{u.full_name} (#{FindingUserAssignment.human_attribute_name(:process_owner)})</b>" :
                u.full_name
            end

            high_risk_weaknesses << [
              "<b>#{Weakness.human_attribute_name(:review_code)}</b>: #{w.review_code}",
              "<b>#{Weakness.human_attribute_name(:state)}</b>: #{w.state_text}",
              "<b>#{Weakness.human_attribute_name(:risk)}</b>: #{w.risk_text}",
              "<b>#{I18n.t(:'finding.audited', :count => audited.size)}</b>: #{audited.join('; ')}",
              "<b>#{Weakness.human_attribute_name(:description)}</b>: #{w.description}"
            ].join("\n")
          end

          if high_risk_weaknesses.size == 0
            t(:'conclusion_committee_report.high_risk_weaknesses_report.without_weaknesses')
          end

          column_data << {
            'business_unit_report_name' => c_r.review.business_unit.name,
            'review' => c_r.review.to_s,
            'score' => c_r.review.score_text,
            'high_risk_weaknesses' => high_risk_weaknesses.blank? ?
              t(:'conclusion_committee_report.high_risk_weaknesses_report.without_weaknesses') :
              high_risk_weaknesses
          }
        end

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

  # Crea un PDF con los informes más notorios para un determinado rango de
  # fechas
  #
  # * POST /follow_up_committee/create_high_risk_weaknesses_report
  def create_high_risk_weaknesses_report
    self.high_risk_weaknesses_report

    pdf = PDF::Writer.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_pointer PDF_FONT_SIZE

    pdf.add_description_item(
      t(:'follow_up_committee.period.title'),
      t(:'follow_up_committee.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :justify

      pdf.move_pointer PDF_FONT_SIZE

      @notorious_reviews[period].each do |data|
        columns = data[:columns]
        column_data = []

        @column_order.each do |col_name|
          columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |column|
            column.heading = columns[col_name].first
            column.width = pdf.percent_width columns[col_name].last
          end
        end

        if !data[:external] && !@internal_title_showed
          title = t :'follow_up_committee.high_risk_weaknesses_report.internal_audit_weaknesses'
          @internal_title_showed = true
        elsif data[:external] && !@external_title_showed
          title = t :'follow_up_committee.high_risk_weaknesses_report.external_audit_weaknesses'
          @external_title_showed = true
        end

        if title
          pdf.move_pointer PDF_FONT_SIZE * 2
          pdf.add_title title, (PDF_FONT_SIZE * 1.25).round, :center
        end

        pdf.add_subtitle data[:name], PDF_FONT_SIZE, PDF_FONT_SIZE

        data[:column_data].each do |row|
          new_row = {}

          row.each do |column_name, column_content|
            new_row[column_name] = column_content.kind_of?(Array) ?
              column_content.join("\n\n").to_iso :
              column_content.to_iso
          end

          column_data << new_row
        end

        unless column_data.blank?
          PDF::SimpleTable.new do |table|
            table.width = pdf.page_usable_width
            table.columns = columns
            table.data = column_data.sort do |row1, row2|
              row1['score'].match(/(\d+)%/)[0].to_i <=>
                row2['score'].match(/(\d+)%/)[0].to_i
            end
            table.column_order = @column_order
            table.split_rows = true
            table.row_gap = PDF_FONT_SIZE
            table.font_size = (PDF_FONT_SIZE * 0.75).round
            table.shade_color = Color::RGB.from_percentage(95, 95, 95)
            table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
            table.heading_font_size = PDF_FONT_SIZE
            table.shade_headings = true
            table.position = :left
            table.orientation = :right
            table.render_on pdf
          end
        else
          pdf.text(
            t(:'follow_up_committee.high_risk_weaknesses_report.without_audits_in_the_period'))
        end
      end
    end

    unless @filters.empty?
      pdf.move_pointer PDF_FONT_SIZE
      pdf.text t(:'follow_up_committee.applied_filters',
        :filters => @filters.to_sentence, :count => @filters.size),
        :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full
    end

    pdf.custom_save_as(
      t(:'follow_up_committee.high_risk_weaknesses_report.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'high_risk_weaknesses_report', 0)

    redirect_to PDF::Writer.relative_path(
      t(:'follow_up_committee.high_risk_weaknesses_report.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'high_risk_weaknesses_report', 0)
  end

  private

  def load_privileges #:nodoc:
    @action_privileges.update({
        :synthesis_report => :read,
        :create_synthesis_report => :read,
        :cost_analysis => :read,
        :create_cost_analysis => :read,
        :weaknesses_by_state => :read,
        :create_weaknesses_by_state => :read,
        :weaknesses_by_risk => :read,
        :create_weaknesses_by_risk => :read,
        :weaknesses_by_audit_type => :read,
        :create_weaknesses_by_audit_type => :read,
        :high_risk_weaknesses_report => :read,
        :create_high_risk_weaknesses_report => :read
      })
  end
end