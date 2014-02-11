class ProcedureControlSubitem < ActiveRecord::Base
  include Parameters::Relevance

  # Alias de atributos
  alias_attribute :label, :control_objective_text

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  before_validation(:on => :create) { fill_control_objective_text }

  # Named scopes
  scope :list_for_item, ->(procedure_control_item_id) {
    where(:procedure_control_item_id => procedure_control_item_id)
  }

  scope :list_not_in, ->(control_objective_ids) {
    where(
      'control_objective_id NOT IN :control_objectives_ids',
      {:control_objectives_ids => control_objective_ids}
    )
  }

  # Restricciones
  validates :control_objective_text, :control_objective_id,
    :relevance, :order, :presence => true
  validates :procedure_control_item_id, :control_objective_id,
    :relevance, :order, :numericality => {:only_integer => true},
    :allow_nil => true
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
  has_one :control, -> { order("#{Control.table_name}.order ASC") },
    :as => :controllable, :dependent => :destroy

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

  def relevance_text(show_value = false)
    relevance = self.class.relevances.detect { |r| r.last == self.relevance }

    if relevance
      text = I18n.t("relevance_types.#{relevance.first}")

      return show_value ? [text, "(#{relevance.last})"].join(' ') : text
    end
  end
end
