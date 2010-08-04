require File.join('modules', 'follow_up_common_reports')

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

  # Muestra un reporte con la efectividad del control
  #
  # * GET /follow_up_committee/control_effectiveness
  # * GET /follow_up_committee/control_effectiveness.xml
  def control_effectiveness
    @title = t :'follow_up_committee.control_effectiveness'

    resume = {}
    ControlObjectiveItem.find_in_batches(
      :include => [
        :review => [:period, {:plan_item => :business_unit}],
        :control_objective => :process_control],
      :conditions => {
        Period.table_name => {:organization_id => get_organization}
      }
    ) do |control_objective_items|
      control_objective_items.each do |coi|
        organization = coi.review.organization.name
        review = coi.review
        period = review.period.inspect
        business_unit = review.business_unit.name
        process_control = coi.control_objective.process_control.name

        resume[organization] ||= {}
        resume[organization][period] ||= {}
        resume[organization][period][business_unit] ||= {}
        resume_bu = resume[organization][period][business_unit]
        resume_bu[review.identification] ||= {}
        resume_bu[review.identification][process_control] ||= []
        resume_bu[review.identification][process_control] << [
          coi.effectiveness, coi.relevance]
      end
    end

    @effectiveness_resume = resume

    respond_to do |format|
      format.html # control_effectiveness.html.erb
      format.xml  { render :xml => @effectiveness_resume }
    end
  end

  # Muestra un reporte con las debilidades y/o oportunidades en estado pendiente
  #
  # * GET /follow_up_committee/pending_findings
  # * GET /follow_up_committee/pending_findings.xml
  def pending_findings
    @title = t :'follow_up_committee.pending_findings'

    query = "#{Period.table_name}.organization_id IN (:organizations)"
    query_params = {:organizations => @auth_user.organizations.map { |o| o.id }}
    query << ' AND final = :boolean_false'
    query_params[:boolean_false] = false

    if params[:period].to_i > 0
      query << " AND #{Review.table_name}.period_id = :period"
      query_params[:period] = params[:period].to_i
    end

    if params[:risk] && !params[:risk].strip.empty?
      query << ' AND risk = :risk'
      query_params[:risk] = params[:risk].to_i
    end

    if params[:expired] && !params[:expired].strip.empty?
      expired = params[:expired].to_i
      query << " AND follow_up_date #{(expired == 1 ? '<' : '>=')} :follow_date"
      query_params[:follow_date] = Time.now
    end

    @pending_findings = Finding.paginate(:page => params[:page],
      :per_page => APP_LINES_PER_PAGE,
      :include => {:control_objective_item => {:review => :period}},
      # TODO: Agregar la condicion para que filtre sólo las "pendientes"
      :conditions => [query, query_params],
      :order => 'period_id DESC, review_id DESC'
    )

    respond_to do |format|
      format.html # pending_findings.html.erb
      format.xml  { render :xml => @pending_findings }
    end
  end

  # Muestra un resumen de las observaciones de las debilidades
  #
  # * GET /follow_up_committee/weakness_summary
  # * GET /follow_up_committee/weakness_summary.xml
  def weakness_summary
    @title = t :'follow_up_committee.weakness_summary'

    summary = {}
    risks_hash = {}
    states_hash = Finding::STATUS.invert
    @all_risks = Parameter.all_parameters(:admin_finding_risk_levels)

    @all_risks.each do |risk|
      risk.value.each { |rl| risks_hash[rl[1]] = rl[0] }
    end

    risks_hash.keys.each { |risk_name| summary[risk_name] = {} }

    Weakness.find_in_batches(
      :include => {:control_objective_item =>
          {:review => [:period, {:plan_item => :business_unit}]}},
      :conditions => {
        Period.table_name => {:organization_id => get_organization},
        :final => false
      }
    ) do |weaknesses|
      weaknesses.each do |w|
        risk = w.risk
        unit = w.control_objective_item.review.business_unit.name
        state = states_hash[w.state]

        if risk && state
          summary[risk][unit] ||= {}
          summary[risk][unit][state] ||= 0
          summary[risk][unit][state] = summary[risk][unit][state] + 1
        end
      end
    end

    @weakness_summary = summary

    respond_to do |format|
      format.html # weakness_summary.html.erb
      format.xml  { render :xml => @weakness_summary }
    end
  end

  # Crea un PDF con una síntesis de las observaciones para un determinado rango
  # de fechas
  #
  # * GET /follow_up_committee/synthesis_report
  # * POST /follow_up_committee/synthesis_report
  def synthesis_report
    @title = t :'follow_up_committee.synthesis_report_title'
    @from_date, @to_date = *make_date_range(params[:synthesis_report])
    @column_order = ['business_unit_report_name', 'review', 'score',
        'process_control', 'weaknesses_count', 'oportunities_count']
    @filters = []
    @risk_levels = []
    @audits_by_business_unit = []
    conclusion_reviews = ConclusionFinalReview.list_all_by_date(@from_date,
      @to_date)

    if params[:synthesis_report]
      unless params[:synthesis_report][:business_unit_type].blank?
        @selected_business_unit = BusinessUnitType.find(
          params[:synthesis_report][:business_unit_type])
        conclusion_reviews = conclusion_reviews.by_business_unit_type(
          @selected_business_unit.id)
        @filters << "<b>#{BusinessUnitType.human_name}</b> = " +
          "\"#{@selected_business_unit.name.strip}\""
      end

      unless params[:synthesis_report][:business_unit].blank?
        business_units = params[:synthesis_report][:business_unit].split(
          SPLIT_AND_TERMS_REGEXP).uniq.map(&:strip)

        unless business_units.empty?
          conclusion_reviews = conclusion_reviews.by_business_unit_names(
            *business_units)
          @filters << "<b>#{BusinessUnit.human_name}</b> = " +
            "\"#{params[:synthesis_report][:business_unit].strip}\""
        end
      end
    end

    business_unit_types = @selected_business_unit ?
      [@selected_business_unit] : BusinessUnitType.list

    business_unit_types.each do |but|
      columns = {'business_unit_report_name' => [but.business_unit_label, 15],
        'review' => [Review.human_name, 16],
        'score' => ["#{Review.human_attribute_name('score')} (1)", 15],
        'process_control' =>
          ["#{BestPractice.human_attribute_name(:process_controls)} (2)", 30],
        'weaknesses_count' => ["#{t(:'review.weaknesses_count')} (3)", 12],
        'oportunities_count' => ["#{t(:'review.oportunities_count')} (4)", 12]}
      column_data = []
      review_scores = []
      name = but.name

      conclusion_reviews.each do |c_r|
        if c_r.review.business_unit.business_unit_type_id == but.id
          process_controls = {}
          weaknesses_count = {}

          c_r.review.control_objective_items.each do |coi|
            process_controls[coi.process_control.name] ||= []
            process_controls[coi.process_control.name] << coi.effectiveness
          end

          process_controls.each do |pc, effectiveness|
            process_controls[pc] = effectiveness.inject(0) {|t, e| t + e}
            process_controls[pc] /= effectiveness.size
          end

          c_r.review.weaknesses.each do |w|
            @risk_levels |= parameter_in(@auth_organization.id,
              :admin_finding_risk_levels, w.created_at).
              sort { |r1, r2| r2[1] <=> r1[1] }.map { |r| r.first }

            weaknesses_count[w.risk_text] ||= 0
            weaknesses_count[w.risk_text] += 1
          end

          weaknesses_count_text = weaknesses_count.values.sum == 0 ?
            t(:'follow_up_committee.synthesis_report.without_weaknesses') :
            @risk_levels.map { |risk| "#{risk}: #{weaknesses_count[risk] || 0}"}
          process_control_text = process_controls.sort do |pc1, pc2|
            pc1[1] <=> pc2[1]
          end.map { |pc| "#{pc[0]} (#{'%.2f' % pc[1]}%)" }
          oportunities_count_text = c_r.review.final_oportunities.count > 0 ?
            c_r.review.final_oportunities.count.to_s :
            t(:'conclusion_committee_report.synthesis_report.without_oportunities')

          review_scores << c_r.review.effectiveness
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

      @audits_by_business_unit << {
        :name => name,
        :external => but.external,
        :columns => columns,
        :column_data => column_data,
        :review_scores => review_scores
      }
    end

    unless params[:download].blank?
      pdf = PDF::Writer.create_generic_pdf :landscape

      pdf.add_generic_report_header @auth_organization

      pdf.add_title t(:'follow_up_committee.synthesis_report.title'),
        PDF_FONT_SIZE, :center

      pdf.move_pointer PDF_FONT_SIZE

      pdf.add_title t(:'follow_up_committee.synthesis_report.subtitle'),
        PDF_FONT_SIZE, :center

      pdf.move_pointer PDF_FONT_SIZE

      pdf.add_description_item(
        t(:'follow_up_committee.period.title'),
        t(:'follow_up_committee.period.range',
          :from_date => I18n.l(@from_date, :format => :long),
          :to_date => I18n.l(@to_date, :format => :long)))

      unless @selected_business_unit
        unless @audits_by_business_unit.blank?
          count = 0
          total = @audits_by_business_unit.inject(0) do |sum, data|
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
          t(:'conclusion_committee_report.synthesis_report.organization_score_note',
            :audit_types =>
              @audits_by_business_unit.map {|data| data[:name]}.to_sentence),
          :font_size => (PDF_FONT_SIZE * 0.75).round)
      end

      @audits_by_business_unit.each do |data|
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
            title = t(:'conclusion_committee_report.synthesis_report.generic_score_average',
              :audit_type => data[:name])
            text = "<b>#{title}</b>: <i>#{(scores.sum.to_f / scores.size).round}%</i>"
          else
            text = t(:'conclusion_committee_report.synthesis_report.without_audits_in_the_period')
          end

          pdf.move_pointer PDF_FONT_SIZE

          pdf.text text, :font_size => PDF_FONT_SIZE
        else
          pdf.text t(:'follow_up_committee.synthesis_report.without_audits_in_the_period')
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
  end

  # Crea un PDF con un análisis de costos para un determinado rango de fechas
  #
  # * GET /follow_up_committee/cost_analysis
  # * POST /follow_up_committee/cost_analysis
  def cost_analysis
    @title = t :'follow_up_committee.cost_analysis_title'
    @from_date, @to_date = *make_date_range(params[:cost_analysis])
    @column_order = [['business_unit', 20], ['project', 20], ['review', 10],
      ['audit_cost', 25], ['audited_cost', 25]]
    @weaknesses_data = []
    @oportunities_data = []
    total_weaknesses_audit_cost, total_weaknesses_audited_cost = 0, 0
    total_oportunities_audit_cost, total_oportunities_audited_cost = 0, 0
    weaknesses_by_review = Weakness.list_all_by_date(@from_date, @to_date).
      finals(false).group_by(&:review)
    oportunities_by_review  = Oportunity.list_all_by_date(@from_date, @to_date).
      finals(false).group_by(&:review)

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
        @weaknesses_data << {
          'business_unit' => review.plan_item.business_unit.name.to_iso,
          'project' => review.plan_item.project.to_iso,
          'review' => review.identification.to_iso,
          'audit_cost' => audit_cost.to_s,
          'audited_cost' => audited_cost.to_s
        }
      end
      
      @weaknesses_data << {
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
        @oportunities_data << {
          'business_unit' => review.plan_item.business_unit.name.to_iso,
          'project' => review.plan_item.project.to_iso,
          'review' => review.identification.to_iso,
          'audit_cost' => audit_cost.to_s,
          'audited_cost' => audited_cost.to_s
        }
      end
      
      @oportunities_data << {
        'business_unit' => '', 'project' => '', 'review' => '',
        'audit_cost' => "<b>#{total_oportunities_audit_cost}</b>",
        'audited_cost' => "<b>#{total_oportunities_audited_cost}</b>"
      }
    end

    unless params[:download].blank?
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
      pdf.add_title t(:'follow_up_committee.cost_analysis.title'),
        PDF_FONT_SIZE, :center

      pdf.move_pointer PDF_FONT_SIZE

      pdf.add_description_item(
        t(:'follow_up_committee.period.title'),
        t(:'follow_up_committee.period.range',
          :from_date => l(@from_date, :format => :long),
          :to_date => l(@to_date, :format => :long)))

      pdf.move_pointer PDF_FONT_SIZE

      pdf.add_title "#{t(:'follow_up_committee.cost_analysis.weaknesses')}\n",
        PDF_FONT_SIZE, :center

      unless @weaknesses_data.blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = @weaknesses_data
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

      unless @oportunities_data.blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = @oportunities_data
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
  end

  private

  def load_privileges #:nodoc:
    @action_privileges.update({
        :control_effectiveness => :read,
        :pending_findings => :read,
        :weakness_summary => :read,
        :synthesis_report => :read,
        :cost_analysis => :read,
        :weaknesses_by_state => :read,
        :weaknesses_by_risk => :read,
        :weaknesses_by_audit_type => :read
      })
  end
end