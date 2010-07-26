require 'pdf/simpletable'

# =Controlador de procedimientos y pruebas de control
#
# Lista, muestra, crea, modifica y elimina procedimientos y pruebas de control
# (#ProcedureControl) y sus ítems (#ProcedureControlItem y
# #ProcedureControlSubitem)
class ProcedureControlsController < ApplicationController
  before_filter :auth, :load_privileges, :check_privileges
  hide_action :find_with_organization, :update_auth_user_id, :load_privileges

  # Lista los procedimientos y pruebas de control
  #
  # * GET /procedure_controls
  # * GET /procedure_controls.xml
  def index
    @title = t :'procedure_control.index_title'
    @procedure_controls = ProcedureControl.paginate(
      :page => params[:page],
      :per_page => APP_LINES_PER_PAGE,
      :include => :period,
      :conditions => {
        "#{Period.table_name}.organization_id" => @auth_organization.id
      },
      :order => "#{ProcedureControl.table_name}.created_at DESC"
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @procedure_controls }
    end
  end

  # Muestra el detalle de un procedimiento de control
  #
  # * GET /procedure_controls/1
  # * GET /procedure_controls/1.xml
  def show
    @title = t :'procedure_control.show_title'
    @procedure_control = find_with_organization(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @procedure_control }
    end
  end

  # Permite ingresar los datos para crear un nuevo procedimiento de control
  #
  # * GET /procedure_controls/new
  # * GET /procedure_controls/new.xml
  def new
    @title = t :'procedure_control.new_title'
    @procedure_control = ProcedureControl.new

    clone_id = params[:clone_from].respond_to?(:to_i) ?
      params[:clone_from].to_i : 0

    if exists?(clone_id)
      clone_procedure_control = find_with_organization(clone_id)
    end

    if clone_procedure_control
      clone_procedure_control.procedure_control_items.each do |pci|
        pcs_attributes = pci.procedure_control_subitems.map do |pcs|
          pcs.attributes.merge :id => nil
        end
        
        attributes = pci.attributes.merge(
          :id => nil,
          :procedure_control_subitems_attributes => pcs_attributes
        )

        @procedure_control.procedure_control_items.build(attributes)
      end
    else
      @procedure_control.procedure_control_items.build
    end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @procedure_control }
    end
  end

  # Recupera los datos para modificar un procedimiento de control
  #
  # * GET /procedure_controls/1/edit
  def edit
    @title = t :'procedure_control.edit_title'
    @procedure_control = find_with_organization(params[:id])
  end

  # Crea un nuevo procedimiento de control siempre que cumpla con las
  # validaciones. Además crea los ítems que lo componen.
  #
  # * POST /procedure_controls
  # * POST /procedure_controls.xml
  def create
    @title = t :'procedure_control.new_title'
    @procedure_control = ProcedureControl.new(params[:procedure_control])

    respond_to do |format|
      if @procedure_control.save
        flash[:notice] = t :'procedure_control.correctly_created'
        format.html { redirect_to(edit_procedure_control_path(@procedure_control)) }
        format.xml  { render :xml => @procedure_control, :status => :created, :location => @procedure_control }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @procedure_control.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de un procedimiento de control siempre que cumpla con
  # las validaciones. Además actualiza los ítems que lo componen.
  #
  # * PUT /procedure_controls/1
  # * PUT /procedure_controls/1.xml
  def update
    @title = t :'procedure_control.edit_title'
    @procedure_control = find_with_organization(params[:id])

    respond_to do |format|
      if @procedure_control.update_attributes(params[:procedure_control])
        flash[:notice] = t :'procedure_control.correctly_updated'
        format.html { redirect_to(edit_procedure_control_path(@procedure_control)) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @procedure_control.errors, :status => :unprocessable_entity }
      end
    end
    
  rescue ActiveRecord::StaleObjectError
    flash[:notice] = t :'procedure_control.stale_object_error'
    redirect_to :action => :edit
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
    @procedure_control = find_with_organization(params[:id])
    pdf = PDF::Writer.create_generic_pdf :landscape, false

    pdf.start_page_numbering pdf.absolute_x_middle, (pdf.bottom_margin / 2.0),
      10, :center, t(:'pdf.page_pattern').to_iso, 1
    pdf.add_planning_header @auth_organization, @procedure_control.period
    pdf.add_title ProcedureControl.human_name

    column_order = ['control_objective_text', 'control',
      'compliance_tests', 'effects', 'risk']
    procedure_control_column_order = ['process_control_id', 'aproach',
      'frequency']
    column_width = {'control_objective_text' => 15, 'control' => 35,
      'compliance_tests' => 35, 'effects' => 8, 'risk' => 7}
    procedure_control_column_width = {'process_control_id' => 70,
      'aproach' => 15, 'frequency' => 15}
    columns = {}
    procedure_control_columns = {}
    column_data = []
    
    column_order.each do |c_name|
      columns[c_name] = PDF::SimpleTable::Column.new(c_name) do |column|
        column.heading = ProcedureControlSubitem.human_attribute_name(c_name)
        column.justification = :full
        column.width = pdf.percent_width(column_width[c_name])
      end
    end

    procedure_control_column_order.each do |c_name|
      procedure_control_columns[c_name] = PDF::SimpleTable::Column.new(c_name) do |column|
        column.heading = ProcedureControlItem.human_attribute_name(c_name)
        column.justification = :full
        column.width = pdf.percent_width(procedure_control_column_width[c_name])
      end
    end

    @procedure_control.procedure_control_items.each do |pci|
      column_data = []
      aproachs = parameter_in(@auth_organization.id, :admin_aproach_types,
        pci.created_at)
      frequencies = parameter_in(@auth_organization.id, :admin_frequency_types,
        pci.created_at)
      procedure_control_column_data = [{
        'process_control_id' =>
          "<i><b>#{pci.process_control.name}</b></i>".to_iso,
        'aproach' => ('<i><b>' + help.name_for_option_value(aproachs,
            pci.aproach) + '</b></i>').to_iso,
        'frequency' => ('<i><b>' + help.name_for_option_value(frequencies,
            pci.frequency) + '</b></i>').to_iso
      }]
    
      pdf.move_pointer 12

      unless column_data.blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = procedure_control_columns
          table.data = procedure_control_column_data
          table.column_order = procedure_control_column_order
          table.split_rows = true
          table.font_size = 10
          table.row_gap = 4
          table.shade_color = Color::RGB::Grey90
          table.shade_heading_color = Color::RGB::Grey70
          table.heading_font_size = 10
          table.bold_headings = true
          table.shade_headings = true
          table.outer_line_style = PDF::Writer::StrokeStyle.new(1.5,
            :cap => :butt, :join => :miter)
          table.position = :left
          table.orientation = :right
          table.render_on pdf
        end
      end

      pdf.move_pointer 6

      pci.procedure_control_subitems.each do |pcs|
        column_data << {
          'control_objective_text' => pcs.control_objective_text.to_iso,
          'control' => pcs.controls.first.control.to_iso,
          'compliance_tests' => pcs.controls.first.compliance_tests.to_iso,
          'effects' => pcs.controls.first.effects.to_iso,
          'risk' => pcs.risk_text.to_iso
        }
      end

      unless column_data.blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = column_data
          table.column_order = column_order
          table.font_size = 8
          table.shade_color = Color::RGB::Grey90
          table.shade_heading_color = Color::RGB::Grey70
          table.heading_font_size = 10
          table.row_gap = 12
          table.split_rows = true
          table.bold_headings = true
          table.shade_headings = true
          table.position = :left
          table.orientation = :right
          table.render_on pdf
        end
      end
    end

    pdf.custom_save_as('procedure_control.pdf', 'procedure_controls',
      @procedure_control.id)

    respond_to do |format|
      format.html { redirect_to(PDF::Writer.relative_path(
            'procedure_control.pdf', 'procedure_controls',
            @procedure_control.id)) }
      format.xml  { head :ok }
    end
  end

  # Devuelve los objetivos de control de un proceso de negocio
  #
  # * GET /procedure_controls/get_control_objectives/?process_control=id
  def get_control_objectives
    options = [[t(:'support.select.prompt'), '']]
    control_objectives = ControlObjective.all(
      :conditions => {:process_control_id => params[:process_control]})

    control_objectives.each { |co| options << [co.name, co.id] }

    render :json => options
  end

  # Devuelve los procesos de negocio de una buena práctica
  #
  # * GET /procedure_controls/get_process_controls/?best_practice=id
  def get_process_controls
    options = [[t(:'support.select.prompt'), '']]
    process_controls = ProcessControl.all(
      :conditions => {:best_practice_id => params[:best_practice]})

    process_controls.each { |pc| options << [pc.name, pc.id] }

    render :json => options
  end

  # Devuelve el contenido de un objetivo de control (nombre y controles
  # identificados) formateado con el estándar JSON
  #
  # * GET /procedure_controls/get_json_control_objective/?control_objective=id
  def get_control_objective
    if params[:control_objective]
      control_objective = ControlObjective.first(
        :include => {:process_control => :best_practice},
        :conditions => {:id => params[:control_objective], :best_practices =>
            {:organization_id => @auth_organization.id}}
      )
    end

    control_objective ||= ControlObjective.new

    render :json => control_objective.to_json(:only => [:name, :risk],
      :include => {:controls =>
          {:only => [:control, :effects, :design_tests,:compliance_tests]}})
  end

  private

  # Busca el procedimiento de control indicado siempre que pertenezca a la
  # organización. En el caso que no se encuentre (ya sea que no existe un
  # procedimiento de control con ese ID o que no pertenece a la organización
  # con la que se autenticó el usuario) devuelve nil.
  # _id_::  ID del procedimiento de control que se quiere recuperar
  def find_with_organization(id) #:doc:
    ProcedureControl.first(
      :include => :period,
      :conditions => {
        :id => id,
        "#{Period.table_name}.organization_id" => @auth_organization.id
      },
      :readonly => false
    )
  end

  # Indica si existe el procedimiento de control indicado, siempre que
  # pertenezca a la organización. En el caso que no se encuentre (ya sea que no
  # existe un procedimiento de control con ese ID o que no pertenece a la
  # organización con la que se autenticó el usuario) devuelve false.
  # _id_::  ID del plan de trabajo que se quiere recuperar
  def exists?(id) #:doc:
    ProcedureControl.first(
      :include => :period,
      :conditions => {
        :id => id,
        "#{Period.table_name}.organization_id" => @auth_organization.id
      }
    )
  end

  def load_privileges #:nodoc:
    @action_privileges.update({
        :export_to_pdf => :read,
        :get_control_objectives => :read,
        :get_process_controls => :read,
        :get_control_objective => :read
      })
  end
end