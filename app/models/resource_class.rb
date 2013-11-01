class ResourceClass < ActiveRecord::Base
  include ParameterSelector

  has_paper_trail meta: {
    organization_id: Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Constantes
  TYPES = {
    human: 0,
    material: 1
  }

  # Named scopes
  scope :human_resources, -> {
    where(
      organization_id: GlobalModelConfig.current_organization_id,
      resource_class_type: TYPES[:human]
    ).order('name ASC')
  }
  scope :material_resources, -> {
    where(
      organization_id: GlobalModelConfig.current_organization_id,
      resource_class_type: TYPES[:material]
    ).order('name ASC')
  }

  # Restricciones de atributos
  attr_readonly :resource_class_type

  # Restricciones
  validates :name, format:{ with: /\A\w[\w\s]*\z/ }, allow_nil: true,
    allow_blank: true
  validates :name, :resource_class_type, :organization_id,
    presence: true
  validates :name, length: { maximum: 255 }, allow_nil: true,
    allow_blank: true
  validates :resource_class_type, inclusion: {in: TYPES.values},
    allow_blank: true, allow_nil: true
  validates :name, uniqueness: {
    scope: :organization_id, case_sensitive: false
  }

  # Relaciones
  belongs_to :organization
  has_many :resources, -> { order('name ASC') }, dependent: :destroy

  accepts_nested_attributes_for :resources, allow_destroy: true

  def to_s
    self.name
  end

  # Definición dinámica de todos los métodos "tipo?"
  TYPES.each do |type, value|
    define_method(:"#{type}?") { self.resource_class_type == value }
  end
end
