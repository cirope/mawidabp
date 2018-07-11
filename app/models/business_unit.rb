class BusinessUnit < ApplicationRecord
  include Auditable
  include BusinessUnits::Scopes
  include ParameterSelector
  include Trimmer

  trimmed_fields :name

  # Alias de atributos
  alias_attribute :label, :name

  # Callbacks
  before_destroy :check_if_can_be_destroyed

  # Restricciones
  validates :name, :presence => true
  validates :name, :length => { :maximum => 255 }, :allow_nil => true,
    :allow_blank => true
  validates :name, :uniqueness =>
    {:case_sensitive => false, :scope => :business_unit_type_id}

  # Relaciones
  belongs_to :business_unit_type, :optional => true
  has_many :plan_items, :dependent => :destroy

  def to_s
    name
  end
  alias display_name to_s

  def as_json(options = nil)
    default_options = {
      :only => [:id],
      :methods => [:label, :informal]
    }

    super(default_options.merge(options || {}))
  end

  def informal
    self.business_unit_type.try(:name)
  end

  def can_be_destroyed?
    if self.plan_items.any?
      self.errors.add :base,
        I18n.t('business_unit_type.errors.business_unit_related')

      false
    else
      true
    end
  end

  private

    def check_if_can_be_destroyed
      throw :abort unless can_be_destroyed?
    end
end
