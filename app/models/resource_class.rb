class ResourceClass < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Constantes
  TYPES = {
    :human => 0,
    :material => 1
  }

  # Asociaciones que deben ser registradas cuando cambien
  @@associations_attributes_for_log = [:resource_ids]
  
  # Named scopes
  named_scope :human_resources, lambda {
    {
      :conditions => {
        :organization_id => GlobalModelConfig.current_organization_id,
        :resource_class_type => TYPES[:human]
      },
      :order => 'name ASC'
    }
  }
  named_scope :material_resources, lambda {
    {
      :conditions => {
        :organization_id => GlobalModelConfig.current_organization_id,
        :resource_class_type => TYPES[:material]
      },
      :order => 'name ASC'
    }
  }

  # Restricciones de atributos
  attr_readonly :resource_class_type

  # Restricciones
  validates_format_of :name, :with => /\A\w[\w\s]*\z/, :allow_nil => true,
    :allow_blank => true
  validates_presence_of :name, :unit, :resource_class_type, :organization_id
  validates_length_of :name, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  validates_numericality_of :unit, :only_integer => true, :allow_nil => true
  validates_inclusion_of :resource_class_type, :in => TYPES.values,
    :allow_blank => true, :allow_nil => true
  validates_uniqueness_of :name, :scope => :organization_id,
    :case_sensitive => false

  # Relaciones
  belongs_to :organization
  has_many :resources, :dependent => :destroy, :order => 'name ASC'

  accepts_nested_attributes_for :resources, :allow_destroy => true

  def to_s
    self.name
  end

  # Definición dinámica de todos los métodos "tipo?"
  TYPES.each do |type, value|
    define_method("#{type}?".to_sym) { self.resource_class_type == value }
  end
end