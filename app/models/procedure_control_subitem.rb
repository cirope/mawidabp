class ProcedureControlSubitem < ActiveRecord::Base
  include ParameterSelector
  
  # Alias de atributos
  alias_attribute :label, :control_objective_text
  
  has_paper_trail :meta => {
    :organization_id => proc { |i| GlobalModelConfig.current_organization_id }
  }
  
  before_validation(:on => :create) { fill_control_objective_text }
  
  # Named scopes
  scope :list_for_item, lambda { |procedure_control_item_id|
    where(:procedure_control_item_id => procedure_control_item_id)
  }

  scope :list_not_in, lambda { |control_objective_ids|
    where(
      'control_objective_id NOT IN :control_objectives_ids',
      {:control_objectives_ids => control_objective_ids}
    )
  }

  # Restricciones
  validates :control_objective_text, :control_objective_id,
    :risk, :order, :presence => true
  validates :procedure_control_item_id, :control_objective_id,
    :risk, :order, :numericality => {:only_integer => true}, :allow_nil => true
  validates_each :control do |record, attr, value|
    has_active_control = value && !value.marked_for_destruction?

    record.errors.add attr, :blank unless has_active_control
  end
  validates_each :control_objective_id do |record, attr, value|
    pci = record.procedure_control_item

    is_duplicated = pci && pci.procedure_control_subitems.any? do |pcs|
      another_record = (!record.new_record? && pcs.id != record.id) ||
        (record.new_record? && pcs.object_id != record.object_id)

      pcs.control_objective_id == record.control_objective_id &&
        another_record && !record.marked_for_destruction?
    end

    record.errors.add attr, :taken if is_duplicated
  end

  # Relaciones
  belongs_to :control_objective
  belongs_to :procedure_control_item
  has_one :control, :as => :controllable, :dependent => :destroy,
    :order => "#{Control.table_name}.order ASC"

  accepts_nested_attributes_for :control, :allow_destroy => true

  def initialize(attributes = nil, options = {})
    super(attributes, options)

    self.build_control unless self.control
  end
  
  def as_json(options = nil)
    default_options = {
      :only => [:id],
      :methods => [:label, :informal]
    }
    
    super(default_options.merge(options || {}))
  end
  
  def informal
    self.control_objective.try(:process_control).try(:name)
  end

  def fill_control_objective_text
    self.control_objective_text ||= self.control_objective.try(:name)
  end

  def risk_text
    risks = self.get_parameter(:admin_control_objective_risk_levels)
    risk = risks.detect { |r| r.last == self.risk }

    risk ? risk.first : ''
  end
end