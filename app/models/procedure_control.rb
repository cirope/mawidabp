class ProcedureControl < ActiveRecord::Base
  include ParameterSelector
  include PaperTrail::DependentDestroy

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  # Named scope
  scope :list, -> { where(organization_id: Organization.current_id) }
  scope :list_by_period, ->(period_id) {
    includes(:period).where(
      "#{table_name}.period_id" => period_id
    ).order('number DESC').references(:periods)
  }

  # Restricciones
  validates :period_id, :organization_id, :presence => true
  validates :period_id, :numericality => {:only_integer => true},
    :allow_nil => true
  validates :period_id, :uniqueness => true, :allow_nil => true,
    :allow_blank => true

  # Relaciones
  belongs_to :period
  belongs_to :organization
  has_many :procedure_control_items, -> { order("#{ProcedureControlItem.table_name}.order ASC") },
    :dependent => :destroy, :after_add => :assign_procedure_control

  accepts_nested_attributes_for :procedure_control_items, :allow_destroy => true

  def assign_procedure_control(procedure_control_item)
    procedure_control_item.procedure_control = self
  end
end
