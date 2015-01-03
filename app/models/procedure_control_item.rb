class ProcedureControlItem < ActiveRecord::Base
  include Parameters::Approach
  include Parameters::Frequency
  include Comparable

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  scope :list_for_process_control, ->(process_control_id) {
    where(:process_control_id => process_control_id)
  }

  # Restricciones
  validates :process_control_id, :aproach, :frequency, :order, :presence => true
  validates :process_control_id, :procedure_control_id, :aproach, :frequency,
    :order, :numericality => {:only_integer => true}, :allow_nil => true
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
  has_many :procedure_control_subitems, -> { order("#{ProcedureControlSubitem.table_name}.order ASC") },
    :dependent => :destroy, :after_add => :assign_procedure_control_item
  has_many :control_objectives, -> { uniq },  :through => :process_control

  accepts_nested_attributes_for :procedure_control_subitems,
    :allow_destroy => true

  def <=>(other)
    if other.kind_of?(ProcedureControlItem)
      self.order <=> other.order
    else
      -1
    end
  end

  def label
    process_control.name
  end

  def informal
    best_practice.name
  end

  def as_json(options = nil)
    default_options = {
      :only => [:id],
      :methods => [:label, :informal]
    }

    super(default_options.merge(options || {}))
  end

  def assign_procedure_control_item(procedure_control_subitem)
    procedure_control_subitem.procedure_control_item = self
  end
end
