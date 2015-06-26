class BusinessUnitType < ActiveRecord::Base
  include Trimmer

  trimmed_fields :name, :business_unit_label, :project_label

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  alias_attribute :label, :name

  # Named scopes
  scope :list, -> {
    where(organization_id: Organization.current_id).order(
      :external => :asc, :name => :asc
    )
  }
  scope :internal_audit, -> { where( external: false) }
  scope :external_audit, -> { where( external: true) }

  # Restricciones
  validates :name, :business_unit_label, :presence => true
  validates :name, :business_unit_label, :project_label,
    :length => { :maximum => 255 }, :allow_nil => true, :allow_blank => true
  validates :name, :uniqueness =>
    {:case_sensitive => false, :scope => :organization_id}
  validates_each :business_units do |record, attr, value|
    locked = false

    unless value.all? {|bu| !bu.marked_for_destruction? || bu.can_be_destroyed?}
      locked = true
    end

    record.errors.add attr, :locked if locked
  end

  # Callbacks
  before_destroy :can_be_destroyed?

  # Relaciones
  belongs_to :organization
  has_many :business_units, -> { order(name: :asc) }, :dependent => :destroy

  accepts_nested_attributes_for :business_units, :allow_destroy => true

  def can_be_destroyed?
    self.business_units.all?(&:can_be_destroyed?)
  end

  def as_json(options = nil)
    default_options = {
      :only => [:id],
      :methods => [:label]
    }

    super(default_options.merge(options || {}))
  end
end
