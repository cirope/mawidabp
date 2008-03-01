class ProcedureControlSubitem < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }
  
  before_validation_on_create :fill_control_objective_text
  
  # Named scopes
  named_scope :list_for_item, lambda { |procedure_control_item_id|
    {
      #:select => connection.distinct('control_objective_id', nil),
      :conditions => { :procedure_control_item_id => procedure_control_item_id }
    }
  }

  named_scope :list_not_in, lambda { |control_objective_ids|
    {
      :conditions => ['control_objective_id NOT IN :control_objectives_ids',
        {:control_objectives_ids => control_objective_ids}]
    }
  }

  # Restricciones
  validates_presence_of :control_objective_text, :control_objective_id,
    :risk, :order
  validates_numericality_of :procedure_control_item_id, :control_objective_id,
    :risk, :order, :only_integer => true, :allow_nil => true
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

  def fill_control_objective_text
    if self.control_objective
      self.control_objective_text ||= self.control_objective.name
    end
  end

  def risk_text
    risks = self.get_parameter(:admin_control_objective_risk_levels)
    risk = risks.detect { |r| r.last == self.risk }

    risk ? risk.first : ''
  end
end