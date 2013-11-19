class Detract < ActiveRecord::Base
  include ParameterSelector

  has_paper_trail meta: { organization_id: ->(obj) { Organization.current_id } }

  default_scope -> { where(organization_id: Organization.current_id) }

  scope :for_organization, ->(organization) {}

  # Callbacks
  after_initialize :set_organization

  # Restricciones sobre los atributos
  attr_readonly :organization_id

  # Restricciones
  validates :value, :user_id, :presence => true
  validates :value, :numericality =>
    {:greater_than_or_equal_to => 0, :less_than_or_equal_to => 1},
    :allow_nil => true, :allow_blank => true

  # Relaciones
  belongs_to :user
  belongs_to :organization

  def set_organization
    self.organization_id ||= Organization.current_id
  end
end
