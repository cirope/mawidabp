class ProcedureControlItem < ActiveRecord::Base
  include ParameterSelector
  include Comparable

  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Asociaciones que deben ser registradas cuando cambien
  @@associations_attributes_for_log = [:procedure_control_subitem_ids]

  scope :list_for_process_control, lambda { |process_control_id|
    {
      :conditions => { :process_control_id => process_control_id }
    }
  }
  
  # Restricciones
  validates_presence_of :process_control_id, :aproach, :frequency, :order
  validates_numericality_of :process_control_id, :procedure_control_id,
    :aproach, :frequency, :order, :only_integer => true, :allow_nil => true
  validates_each :process_control_id do |record, attr, value|
    pc = record.procedure_control

    is_duplicated = pc && pc.procedure_control_items.any? do |pci|
      another_record = (!record.new_record? && pci.id != record.id) ||
        (record.new_record? && pci.object_id != record.object_id)

      pci.process_control_id == record.process_control_id && another_record &&
        !record.marked_for_destruction?
    end

    record.errors.add attr, :taken if is_duplicated
  end
  
  # Relaciones
  belongs_to :process_control
  belongs_to :procedure_control
  has_one :best_practice, :through => :process_control
  has_many :procedure_control_subitems, :dependent => :destroy,
    :after_add => :assign_procedure_control_item, :order => '"order" ASC'
  has_many :control_objectives, :through => :process_control, :uniq => true

  accepts_nested_attributes_for :procedure_control_subitems,
    :allow_destroy => true

  def <=>(other)
    self.order <=> other.order
  end

  def assign_procedure_control_item(procedure_control_subitem)
    procedure_control_subitem.procedure_control_item = self
  end
end