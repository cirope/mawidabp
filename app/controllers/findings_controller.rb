# -*- coding: utf-8 -*-
# =Controlador de debilidades y oportunidades de mejora
#
# Lista, muestra, modifica y elimina debilidades (#Weakness) y oportunidades de
# mejora (#Oportunity) y sus respuestas (#FindingAnswer)
class FindingsController < ApplicationController
  before_filter :auth, :load_privileges, :check_privileges
  hide_action :load_privileges, :find_with_organization, :prepare_parameters
  layout proc{ |controller| controller.request.xhr? ? false : 'application' }

  autoload :CSV, 'csv'
  respond_to :csv

  # Lista las debilidades y oportunidades
  #
  # * GET /findings
  # * GET /findings.xml
  def index
    @title = t 'finding.index_title'
    @selected_user = User.find(params[:user_id]) if params[:user_id]
    @self_and_descendants = @auth_user.descendants + [@auth_user]
    @related_users = @auth_user.related_users_and_descendants
    @is_responsible = params[:as_responsible]
    default_conditions = {
      :final => false,
      Period.table_name => {:organization_id => @auth_organization.id}
    }

    if @auth_user.committee? || @selected_user
      if @selected_user
          default_conditions[User.table_name] = {:id => params[:user_id]}

          if @is_responsible
            default_conditions[FindingUserAssignment.table_name] = {
              :responsible_auditor => true
            }
          end
      end
    else
      self_and_descendants_ids = @self_and_descendants.map(&:id) +
        @related_users.map(&:id)
      default_conditions[User.table_name] = {
        :id => self_and_descendants_ids.include?(@selected_user.try(:id)) ?
          @selected_user.id : self_and_descendants_ids
      }
    end

    if params[:ids]
      default_conditions[:id] = params[:ids]
    else
      default_conditions[:state] = params[:completed] == 'incomplete' ?
        Finding::PENDING_STATUS - [Finding::STATUS[:incomplete]] :
        Finding::STATUS.values - Finding::PENDING_STATUS - [Finding::STATUS[:revoked]]
    end

    build_search_conditions Finding, default_conditions

    @findings = Finding.includes(
      {
        :control_objective_item => {
          :review => [:conclusion_final_review, :period, :plan_item]
        }
      }, :users
    ).where(@conditions).order(
      @order_by || [
        "#{Review.table_name}.created_at DESC",
        "#{Finding.table_name}.state ASC",
        "#{Finding.table_name}.review_code ASC"
      ]
    )

    respond_to do |format|
      format.html {
        @findings = @findings.paginate(
          :page => params[:page], :per_page => APP_LINES_PER_PAGE
        )

        if @findings.size == 1 && !@query.blank? && !params[:page]
          redirect_to finding_url(params[:completed], @findings.first)
        end
      } # index.html.erb
      format.xml  {
        headers['Cache-Control'] = "max-age=1"
        headers['Content-disposition'] = "attachment; filename=#{@title.underscore.sanitized_for_filename}.xml"
        render :xml => @findings
      }
    end
  end

  # Muestra el detalle de una debilidad u oportunidad
  #
  # * GET /findings/1
  # * GET /findings/1.xml
  def show
    @title = t 'finding.show_title'
    @finding = find_with_organization(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @finding }
    end
  end

  # Recupera los datos para modificar una debilidad u oportunidad
  #
  # * GET /findings/1/edit
  def edit
    @title = t 'finding.edit_title'
    @finding = find_with_organization(params[:id])

    if @finding.nil? ||
        (@auth_user.can_act_as_audited? && !@finding.users.include?(@auth_user))
      redirect_to findings_url
    end
  end

  # Actualiza el contenido de una debilidad u oportunidad siempre que cumpla con
  # las validaciones. Además actualiza el contenido de las respuestas que la
  # componen.
  #
  # * PUT /findings/1
  # * PUT /findings/1.xml
  def update
    @title = t 'finding.edit_title'
    @finding = find_with_organization(params[:id])

    if @finding.nil? ||
        (@auth_user.can_act_as_audited? && !@finding.users.include?(@auth_user))
      raise 'Finding can not be updated'
    end

    # Los auditados no pueden modificar desde observaciones las asociaciones
    if @auth_user.can_act_as_audited?
      params[:finding].delete :finding_user_assignments_attributes
    end

    prepare_parameters

    respond_to do |format|
      Finding.transaction do
        if @finding.update_attributes(params[:finding])
          flash.notice = t 'finding.correctly_updated'
          format.html { redirect_to(edit_finding_url(params[:completed], @finding)) }
          format.xml  { head :ok }
        else
          format.html { render :action => :edit }
          format.xml  { render :xml => @finding.errors, :status => :unprocessable_entity }
          raise ActiveRecord::Rollback
        end
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'finding.stale_object_error'
    redirect_to :action => :edit
  end

  # Lista las observaciones / oportunidades de mejora
  #
  # * GET /findings/export_to_csv
  def export_to_csv
    findings = Finding.find params[:findings] if params[:findings].present?
    detailed = params[:include_details].present?
    completed = params[:completed]
    selected_user = User.find(params[:user_id]) if params[:user_id]
    default_conditions = {
      :final => false,
      Period.table_name => {:organization_id => @auth_organization.id}
    }

    if @auth_user.committee? || selected_user
      if params[:user_id]
        default_conditions[User.table_name] = {:id => params[:user_id]}
      end
    else
      self_and_descendants = @auth_user.descendants + [@auth_user]
      self_and_descendants_ids = self_and_descendants.map(&:id)
      default_conditions[User.table_name] = {
        :id => self_and_descendants_ids.include?(params[:user_id].to_i) ?
          params[:user_id] : self_and_descendants_ids
      }
    end

    if params[:ids]
      default_conditions[:id] = params[:ids]
    else
      default_conditions[:state] = completed == 'incomplete' ?
        Finding::PENDING_STATUS - [Finding::STATUS[:incomplete]] :
        Finding::STATUS.values - Finding::PENDING_STATUS
    end

    build_search_conditions Finding, default_conditions

    findings = Finding.includes(
      {
        :control_objective_item => {
          :review => [:conclusion_final_review, :period, :plan_item]
        }
      }, :users
    ).order(
      @order_by || [
        "#{Review.table_name}.created_at DESC",
        "#{Finding.table_name}.state ASC",
        "#{Finding.table_name}.review_code ASC"
      ]
    ).where(@conditions)

    if detailed
      columns = 11
    else
      columns = 9
    end

    buffer = ''
    rows = []

    header = Finding.to_csv(detailed, completed)
    rows << header

    findings.try(:each) do |finding|
      rows << finding.to_csv(detailed, completed)
    end

    rows.each do |row|
      parsed_cells = CSV.generate_row(row, columns, buffer, ?;)
    end

    filename = t 'finding.csv_name'

    respond_with findings do |format|
      format.csv { render :csv => buffer, :filename => filename }
    end
  end

  # Lista las observaciones / oportunidades de mejora
  #
  # * GET /findings/export_to_pdf
  def export_to_pdf
    selected_user = User.find(params[:user_id]) if params[:user_id]
    detailed = params[:include_details].present?
    default_conditions = {
      :final => false,
      Period.table_name => {:organization_id => @auth_organization.id}
    }

    if @auth_user.committee? || selected_user
      if params[:user_id]
        default_conditions[User.table_name] = {:id => params[:user_id]}
      end
    else
      self_and_descendants = @auth_user.descendants + [@auth_user]
      self_and_descendants_ids = self_and_descendants.map(&:id)
      default_conditions[User.table_name] = {
        :id => self_and_descendants_ids.include?(params[:user_id].to_i) ?
          params[:user_id] : self_and_descendants_ids
      }
    end

    if params[:ids]
      default_conditions[:id] = params[:ids]
    else
      default_conditions[:state] = params[:completed] == 'incomplete' ?
        Finding::PENDING_STATUS - [Finding::STATUS[:incomplete]] :
        Finding::STATUS.values - Finding::PENDING_STATUS
    end

    build_search_conditions Finding, default_conditions

    findings = Finding.includes(
      {
        :control_objective_item => {
          :review => [:conclusion_final_review, :period, :plan_item]
        }
      }, :users
    ).order(
      @order_by || [
        "#{Review.table_name}.created_at DESC",
        "#{Finding.table_name}.state ASC",
        "#{Finding.table_name}.review_code ASC"
      ]
    ).where(@conditions)

    pdf = PDF::Writer.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization
    pdf.add_title t('finding.index_title')

    column_order = [
      ['review', [Review.model_name.human,
          PlanItem.human_attribute_name(:project)].to_sentence, 0],
      ['project', PlanItem.human_attribute_name(:project), 0],
      ['review_code', Finding.human_attribute_name(:review_code), 0],
      ['description', Finding.human_attribute_name(:description),
        detailed ? 48 : 80],
      ['rescheduled', t('weakness.previous_follow_up_dates') +
          " (#{Finding.human_attribute_name(:rescheduled)})", 10],
      ['date', Finding.human_attribute_name(params[:completed] == 'incomplete' ?
            :follow_up_date : :solution_date), 10]
    ]
    columns = {}
    column_data = []

    if detailed
      column_order << [
        'audit_comments', Finding.human_attribute_name(:audit_comments), 15
      ]
      column_order << [
        'answer', Finding.human_attribute_name(:answer), 17
      ]
    end

    column_order.each do |col_id, col_name, col_with|
      if col_with > 0
        columns[col_id] = PDF::SimpleTable::Column.new(col_id) do |c|
          c.heading = col_name
          c.width = pdf.percent_width col_with
        end
      end
    end

    unless (@columns - ['issue_date']).blank? || @query.blank?
      pdf.move_pointer PDF_FONT_SIZE
      pointer_moved = true
      filter_columns = (@columns - ['issue_date']).map do |c|
        "<b>#{column_order.detect { |co| co[0] == c }[1]}</b>"
      end

      pdf.text t('finding.pdf.filtered_by',
        :query => @query.map {|q| "<b>#{q}</b>"}.join(', '),
        :columns => filter_columns.to_sentence,
        :count => (@columns - ['issue_date']).size),
        :font_size => (PDF_FONT_SIZE * 0.75).round
    end

    unless @order_by_column_name.blank?
      pdf.move_pointer PDF_FONT_SIZE unless pointer_moved
      pdf.text t('finding.pdf.sorted_by',
        :column => "<b>#{@order_by_column_name}</b>"),
        :font_size => (PDF_FONT_SIZE * 0.75).round
    end

    findings.limit(FINDING_MAX_PDF_ROWS).each do |finding|
      date = params[:completed] == 'incomplete' ? finding.follow_up_date :
        finding.solution_date
      date_text = l(date, :format => :minimal).to_iso if date
      stale = finding.kind_of?(Weakness) && finding.being_implemented? &&
        finding.follow_up_date < Date.today
      being_implemented = finding.kind_of?(Weakness) && finding.being_implemented?
      rescheduled_text = being_implemented && !finding.rescheduled? ?
        t('label.no') : ''

      if being_implemented && finding.rescheduled?
        dates = []
        follow_up_dates = finding.all_follow_up_dates

        if follow_up_dates.last == finding.follow_up_date
          follow_up_dates.slice(-1)
        end

        follow_up_dates.each { |fud| dates << l(fud, :format => :minimal) }

        rescheduled_text << dates.join("\n")
      end

      audited = finding.reload.users.select(&:audited?).map do |u|
        finding.process_owners.include?(u) ?
          "<b>#{u.full_name} (#{FindingUserAssignment.human_attribute_name(:process_owner)})</b>" :
          u.full_name
      end

      finding_data = [
        "<b>#{[Review.model_name.human, PlanItem.human_attribute_name(:project)].to_sentence}</b>: #{finding.review.to_s}",
        "<b>#{Weakness.human_attribute_name(:review_code)}</b>: #{finding.review_code}",
        "<b>#{Weakness.human_attribute_name(:state)}</b>: #{finding.state_text}",
        ("<b>#{Weakness.human_attribute_name(:risk)}</b>: #{finding.risk_text.to_iso}" if finding.kind_of?(Weakness)),
        "<b>#{I18n.t('finding.audited', :count => audited.size)}</b>: #{audited.join('; ')}",
        "<b>#{Weakness.human_attribute_name(:description)}</b>: #{finding.description}"
      ].compact.join("\n")

      unless (relations = finding.finding_relations).blank?
        finding_data << "\n<b>#{t('finding.finding_relations')}</b>: "
        finding_data << relations.map(&:to_s).join(' | ')
      end

      unless (repeated_ancestors = finding.repeated_ancestors).blank?
        finding_data << "\n<b>#{t('finding.repeated_ancestors')}</b>: "
        finding_data << repeated_ancestors.map(&:to_s).join(' | ')
      end

      unless (repeated_children = finding.repeated_children).blank?
        finding_data << "\n<b>#{t('finding.repeated_children')}</b>: "
        finding_data << repeated_children.map(&:to_s).join(' | ')
      end

      column_data << {
        'description' => finding_data.to_iso,
        'rescheduled' => rescheduled_text.to_iso,
        'date' => stale ? "<b>#{date_text}</b>" : date_text,
        'audit_comments' => (finding.audit_comments.try(:to_iso) if detailed),
        'answer' => (finding.answer.try(:to_iso) if detailed)
      }
    end

    pdf.move_pointer PDF_FONT_SIZE

    unless column_data.blank?
      PDF::SimpleTable.new do |table|
        table.width = pdf.page_usable_width
        table.columns = columns
        table.data = column_data
        table.column_order = column_order.reject{|co| co.last == 0}.map(&:first)
        table.row_gap = (PDF_FONT_SIZE * 1.25).round
        table.split_rows = true
        table.font_size = (PDF_FONT_SIZE * 0.75).round
        table.shade_color = Color::RGB.from_percentage(95, 95, 95)
        table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
        table.heading_font_size = (PDF_FONT_SIZE * 0.75).round
        table.shade_headings = true
        table.position = :left
        table.orientation = :right
        table.render_on pdf
      end
    end

    if findings.count > FINDING_MAX_PDF_ROWS
      pdf.move_pointer PDF_FONT_SIZE
      pdf.text "<b>#{t('finding.pdf.size_warning', :count => FINDING_MAX_PDF_ROWS)}</b>"
    end

    pdf_name = t 'finding.pdf.pdf_name'

    pdf.custom_save_as(pdf_name, Finding.table_name)

    redirect_to PDF::Writer.relative_path(pdf_name, Finding.table_name)
  end

  # Crea el documento de seguimiento de la oportunidad
  #
  # * GET /oportunities/follow_up_pdf/1
  def follow_up_pdf
    finding = find_with_organization(params[:id])

    finding.follow_up_pdf(@auth_organization)

    redirect_to finding.relative_follow_up_pdf_path
  end

  # * POST /findings/auto_complete_for_user
  def auto_complete_for_user
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = [
      'organizations.id = :organization_id',
      "#{User.table_name}.hidden = false"
    ]
    parameters = {:organization_id => @auth_organization.id}
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{User.table_name}.name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.last_name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.function) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.user) LIKE :user_data_#{i}"
      ].join(' OR ')

      parameters[:"user_data_#{i}"] = "%#{Unicode::downcase(t)}%"
    end

    @users = User.includes(:organizations).where(
      [conditions.map {|c| "(#{c})"}.join(' AND '), parameters]
    ).order(
      [
        "#{User.table_name}.last_name ASC",
        "#{User.table_name}.name ASC"
      ]
    ).limit(10)

    respond_to do |format|
      format.json { render :json => @users }
    end
  end

  # * POST /findings/auto_complete_for_finding_relation
  def auto_complete_for_finding_relation
    @tokens = params[:q][0..100].split(SPLIT_AND_TERMS_REGEXP).uniq.map(&:strip)
    @tokens.reject! { |t| t.blank? }
    conditions = [
      ("#{Finding.table_name}.id <> :finding_id" unless params[:finding_id].blank?),
      "#{Finding.table_name}.final = :boolean_false",
      "#{Period.table_name}.organization_id = :organization_id",
      [
        "#{ConclusionReview.table_name}.review_id IS NOT NULL",
        ("#{Review.table_name}.id = :review_id" unless params[:review_id].blank?)
      ].compact.join(' OR ')
    ].compact
    parameters = {
      :boolean_false => false,
      :finding_id => params[:finding_id],
      :organization_id => @auth_organization.id,
      :review_id => params[:review_id]
    }
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{Finding.table_name}.review_code) LIKE :finding_relation_data_#{i}",
        "LOWER(#{Finding.table_name}.description) LIKE :finding_relation_data_#{i}",
        "LOWER(#{ControlObjectiveItem.table_name}.control_objective_text) LIKE :finding_relation_data_#{i}",
        "LOWER(#{Review.table_name}.identification) LIKE :finding_relation_data_#{i}",
      ].join(' OR ')

      parameters[:"finding_relation_data_#{i}"] = "%#{Unicode::downcase(t)}%"
    end

    @findings = Finding.includes(:control_objective_item =>
        {:review => [:period, :conclusion_final_review]}
    ).where([conditions.map {|c| "(#{c})"}.join(' AND '), parameters]).order(
      [
        "#{Review.table_name}.identification ASC",
        "#{Finding.table_name}.review_code ASC"
      ]
    ).limit(5)

    respond_to do |format|
      format.json { render :json => @findings }
    end
  end

  private

  # Busca la debilidad u oportunidad indicada siempre que pertenezca a la
  # organización. En el caso que no se encuentre (ya sea que no existe o que no
  # pertenece a la organización con la que se autenticó el usuario) devuelve
  # nil.
  # _id_::  ID de la debilidad u oportunidad que se quiere recuperar
  def find_with_organization(id) #:doc:
    includes = [{:control_objective_item => {:review => :period}}]
    conditions = {
      :id => id,
      :final => false,
      Period.table_name => {:organization_id => @auth_organization.id}
    }

    if @auth_user.can_act_as_audited?
      includes << :users
      conditions[User.table_name] = {
        :id => @auth_user.descendants.map(&:id) +
          @auth_user.related_users_and_descendants.map(&:id) + [@auth_user.id]
      }
    end

    conditions[:state] = params[:completed] == 'incomplete' ?
      Finding::PENDING_STATUS - [Finding::STATUS[:incomplete]] :
      Finding::STATUS.values - Finding::PENDING_STATUS

    finding = Finding.includes(includes).where(conditions).first(
      :readonly => false
    )

    # TODO: eliminar cuando se corrija el problema que hace que include solo
    # traiga el primer usuario
    finding.try(:reload)

    finding.finding_prefix = true if finding

    finding
  end

  # Elimina los atributos que no pueden ser modificados por usuarios
  # del tipo "Auditado".
  def prepare_parameters
    if @auth_user.can_act_as_audited?
      params[:finding].delete_if do |k,|
        ![:finding_answers_attributes, :costs_attributes].include?(k.to_sym)
      end
    end
  end

  def load_privileges #:nodoc:
    @action_privileges.update(
      :export_to_csv => :read,
      :export_to_pdf => :read,
      :follow_up_pdf => :read,
      :auto_complete_for_user => :read,
      :auto_complete_for_finding_relation => :read
    )
  end
end
