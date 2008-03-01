class ProcedureControl < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Asociaciones que deben ser registradas cuando cambien
  @@associations_attributes_for_log = [:procedure_control_item_ids]
  
  # Restricciones
  validates_presence_of :period_id
  validates_numericality_of :period_id, :allow_nil => true,
    :only_integer => true

  
  # Relaciones
  belongs_to :period
  has_one :organization, :through => :period
  has_many :procedure_control_items, :dependent => :destroy,
    :after_add => :assign_procedure_control,
    :order => "#{ProcedureControlItem.table_name}.order ASC"
  
  accepts_nested_attributes_for :procedure_control_items, :allow_destroy => true

  def assign_procedure_control(procedure_control_item)
    procedure_control_item.procedure_control = self
  end
end