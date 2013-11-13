# =Controlador de procedimientos y pruebas de control
#
# Lista, muestra, crea, modifica y elimina procedimientos y pruebas de control
# (#ProcedureControl) y sus ítems (#ProcedureControlItem y
# #ProcedureControlSubitem)
class ProcedureControlsController < ApplicationController
  before_action :auth, :load_privileges, :check_privileges
  hide_action :find_with_organization, :update_auth_user_id, :load_privileges

  # Lista los procedimientos y pruebas de control
  #
  # * GET /procedure_controls
  # * GET /procedure_controls.xml
  def index
    @title = t 'procedure_control.index_title'
    @procedure_controls = ProcedureControl.includes(:period).where(
      "#{Period.table_name}.organization_id" => current_organization.id
    ).order("#{ProcedureControl.table_name}.created_at DESC").paginate(
      page: params[:page], per_page: APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @procedure_controls }
    end
  end

  # Muestra el detalle de un procedimiento de control
  #
  # * GET /procedure_controls/1
  # * GET /procedure_controls/1.xml
  def show
    @title = t 'procedure_control.show_title'
    @procedure_control = find_with_organization(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @procedure_control }
    end
  end

  # Permite ingresar los datos para crear un nuevo procedimiento de control
  #
  # * GET /procedure_controls/new
  # * GET /procedure_controls/new.xml
  def new
    @title = t 'procedure_control.new_title'
    @procedure_control = ProcedureControl.new

    clone_id = params[:clone_from].respond_to?(:to_i) ?
      params[:clone_from].to_i : 0

    if exists?(clone_id)
      clone_procedure_control = find_with_organization(clone_id)
    end

    if clone_procedure_control
      clone_procedure_control.procedure_control_items.each do |pci|
        pcs_attributes = pci.procedure_control_subitems.map do |pcs|
          pcs.attributes.merge(
            'id' => nil,
            'control_attributes' => pcs.control.attributes.merge('id' => nil)
          )
        end

        attributes = pci.attributes.merge(
          'id' => nil,
          'procedure_control_subitems_attributes' => pcs_attributes
        )

        @procedure_control.procedure_control_items.build(attributes)
      end
    else
      @procedure_control.procedure_control_items.build
    end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @procedure_control }
    end
  end

  # Recupera los datos para modificar un procedimiento de control
  #
  # * GET /procedure_controls/1/edit
  def edit
    @title = t 'procedure_control.edit_title'
    @procedure_control = find_with_organization(params[:id], true)
  end

  # Crea un nuevo procedimiento de control siempre que cumpla con las
  # validaciones. Además crea los ítems que lo componen.
  #
  # * POST /procedure_controls
  # * POST /procedure_controls.xml
  def create
    @title = t 'procedure_control.new_title'
    @procedure_control = ProcedureControl.new(procedure_control_params)

    respond_to do |format|
      if @procedure_control.save
        flash.notice = t 'procedure_control.correctly_created'
        format.html { redirect_to(edit_procedure_control_url(@procedure_control)) }
        format.xml  { render xml: @procedure_control, status: :created, location: @procedure_control }
      else
        format.html { render action: :new }
        format.xml  { render xml: @procedure_control.errors, status: :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de un procedimiento de control siempre que cumpla con
  # las validaciones. Además actualiza los ítems que lo componen.
  #
  # * PATCH /procedure_controls/1
  # * PATCH /procedure_controls/1.xml
  def update
    @title = t 'procedure_control.edit_title'
    @procedure_control = find_with_organization(params[:id], true)

    respond_to do |format|
      if @procedure_control.update(procedure_control_params)
        flash.notice = t 'procedure_control.correctly_updated'
        format.html { redirect_to(edit_procedure_control_url(@procedure_control)) }
        format.xml  { head :ok }
      else
        format.html { render action: :edit }
        format.xml  { render xml: @procedure_control.errors, status: :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'procedure_control.stale_object_error'
    redirect_to action: :edit
  end

  # Elimina un procedimiento de control
  #
  # * DELETE /procedure_controls/1
  # * DELETE /procedure_controls/1.xml
  def destroy
    @procedure_control = find_with_organization(params[:id])
    @procedure_control.destroy

    respond_to do |format|
      format.html { redirect_to(procedure_controls_url) }
      format.xml  { head :ok }
    end
  end

  # Exporta los procedimientos y pruebas de control en formato PDF
  #
  # * GET /procedure_controls/export_to_pdf/1
  def export_to_pdf
    @procedure_control = find_with_organization(params[:id], true)
    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_planning_header current_organization, @procedure_control.period
    pdf.add_title ProcedureControl.model_name.human

    column_order = ['control_objective_text', 'control',
      'compliance_tests', 'sustantive_tests', 'effects', 'relevance']
    column_headers = []

    column_order.each_with_index do |c_name, i|
      column_headers << ([0, 5].include?(i) ?
          ProcedureControlSubitem.human_attribute_name(c_name) :
          Control.human_attribute_name(c_name))
    end

    @procedure_control.procedure_control_items.each do |pci|
      column_data = []

      pdf.move_down PDF_FONT_SIZE
      pdf.move_down((PDF_FONT_SIZE * 0.5).round)

      pci.procedure_control_subitems.each do |pcs|
        column_data << [
          pcs.control_objective_text,
          pcs.control.control,
          pcs.control.compliance_tests,
          pcs.control.sustantive_tests,
          pcs.control.effects,
          pcs.relevance_text
        ]
      end

      unless column_data.blank?
        column_data.each do |data|
          column_headers.each_with_index do |header, i|
            data[i] = '--' if data[i].blank?
            if column_headers.last == header
              data[i] = "#{data[i]}\n\n"
            end
            pdf.text "<b>#{header.upcase}</b>: #{data[i]}", inline_format: true
          end
        end
      end
    end

    pdf.custom_save_as('procedure_control.pdf', 'procedure_controls',
      @procedure_control.id)

    respond_to do |format|
      format.html { redirect_to(Prawn::Document.relative_path(
            'procedure_control.pdf', 'procedure_controls',
            @procedure_control.id)) }
      format.xml  { head :ok }
    end
  end

  # Devuelve los objetivos de control de un proceso de negocio
  #
  # * GET /procedure_controls/get_control_objectives/?process_control=id
  def get_control_objectives
    options = [[t('helpers.select.prompt'), '']]
    control_objectives = ControlObjective.where(
      process_control_id: params[:process_control]
    )

    control_objectives.each { |co| options << [co.name, co.id] }

    render json: options
  end

  # Devuelve los procesos de negocio de una buena práctica
  #
  # * GET /procedure_controls/get_process_controls/?best_practice=id
  def get_process_controls
    options = [[t('helpers.select.prompt'), '']]
    process_controls = ProcessControl.where(
      best_practice_id: params[:best_practice]
    )

    process_controls.each { |pc| options << [pc.name, pc.id] }

    render json: options
  end

  # Devuelve el contenido de un objetivo de control (nombre y controles
  # identificados) formateado con el estándar JSON
  #
  # * GET /procedure_controls/get_json_control_objective/?control_objective=id
  def get_control_objective
    if params[:control_objective]
      control_objective = ControlObjective.includes(
        process_control: :best_practice
      ).where(
        id: params[:control_objective],
        best_practices: { organization_id: current_organization.id }
      ).first
    end

    control_objective ||= ControlObjective.new

    render json: control_objective.to_json(only: [:name, :relevance],
      include: {control: {only:
            [:control, :effects, :design_tests, :compliance_tests, :sustantive_tests]
        }
      }
    )
  end

  private

    def procedure_control_params
      params.require(:procedure_control).permit(
        :period_id, :lock_version,
        procedure_control_items_attributes: [
          :id, :aproach, :frequency, :process_control_id, :order, :_destroy,
          procedure_control_subitems_attributes: [
            :id, :control_objective_text, :relevance, :control_objective_id,
            :order, :_destroy, control_attributes: [
              :id, :control, :design_tests, :compliance_tests,
              :sustantive_tests, :effects
            ]
          ]
        ]
      )
    end

    # Busca el procedimiento de control indicado siempre que pertenezca a la
    # organización. En el caso que no se encuentre (ya sea que no existe un
    # procedimiento de control con ese ID o que no pertenece a la organización
    # con la que se autenticó el usuario) devuelve nil.
    # _id_::  ID del procedimiento de control que se quiere recuperar
    def find_with_organization(id, include_all = false) #:doc:
      include = include_all ? [
        :period, {
          procedure_control_items: [
            {process_control: :control_objectives},
            {procedure_control_subitems: :control}
          ]
        }
      ] : [:period]

      ProcedureControl.includes(*include).where(
        id: id, "#{Period.table_name}.organization_id" => current_organization.id
      ).first
    end

    # Indica si existe el procedimiento de control indicado, siempre que
    # pertenezca a la organización. En el caso que no se encuentre (ya sea que no
    # existe un procedimiento de control con ese ID o que no pertenece a la
    # organización con la que se autenticó el usuario) devuelve false.
    # _id_::  ID del plan de trabajo que se quiere recuperar
    def exists?(id) #:doc:
      ProcedureControl.includes(:period).where(
        id: id, "#{Period.table_name}.organization_id" => current_organization.id
      ).first
    end

    def load_privileges #:nodoc:
      @action_privileges.update(
        export_to_pdf: :read,
        get_control_objectives: :read,
        get_process_controls: :read,
        get_control_objective: :read
      )
    end
end
