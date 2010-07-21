class BusinessUnit < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Callbacks
  before_destroy :can_be_destroyed?

  # Constantes
  INTERNAL_TYPES = {
    :cycle => 0x000,
    :consolidated_substantive => 0x001,
    :branch_offices => 0x002
  }

  EXTERNAL_TYPES = {
    :bcra => 0xe01,
    :external_audit => 0xe02
  }

  TYPES = INTERNAL_TYPES.merge(EXTERNAL_TYPES)

  # Restricciones
  validates_presence_of :name, :business_unit_type
  validates_inclusion_of :business_unit_type, :in => TYPES.values,
    :allow_blank => true, :allow_nil => true
  validates_length_of :name, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  validates_uniqueness_of :name, :case_sensitive => false,
    :scope => :organization_id
  
  # Relaciones
  belongs_to :organization
  has_many :plan_items, :dependent => :destroy

  def can_be_destroyed?
    unless self.plan_items.empty?
      self.errors.add_to_base I18n.t(:'organization.errors.business_unit_related')

      false
    else
      true
    end
  end

  # Definición dinámica de todos los métodos "tipo?"
  TYPES.each do |type, value|
    define_method("#{type}?".to_sym) { self.business_unit_type == value }
  end

  def type_text
    I18n.t "organization.business_unit_#{self.type_sym}.type"
  end

  def report_name_text
    I18n.t "organization.business_unit_#{self.type_sym}.report_name"
  end

  def report_subname_text
    I18n.t "organization.business_unit_#{self.type_sym}.report_subname"
  end

  def type_sym
    TYPES.invert[self.business_unit_type]
  end
end