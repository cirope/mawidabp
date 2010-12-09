class ProcedureControl < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Named scope
  scope :list_by_period, lambda { |period_id|
    includes(:period).where(
      "#{Period.table_name}.organization_id" =>
        GlobalModelConfig.current_organization_id,
      "#{table_name}.period_id" => period_id
    ).order('number DESC')
  }
  
  # Restricciones
  validates :period_id, :presence => true
  validates :period_id, :numericality => {:only_integer => true},
    :allow_nil => true
  validates :period_id, :uniqueness => true, :allow_nil => true,
    :allow_blank => true

  
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