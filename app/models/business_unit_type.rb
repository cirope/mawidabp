class BusinessUnitType < ActiveRecord::Base
  include Trimmer

  trimmed_fields :name, :business_unit_label, :project_label

  has_paper_trail :meta => {
    :organization_id => proc { |i| GlobalModelConfig.current_organization_id }
  }

  # Named scopes
  scope :list, lambda {
    where(:organization_id => GlobalModelConfig.current_organization_id).order(
      ['external ASC', 'name ASC']
    )
  }
  scope :internal_audit, lambda {
    where(
      :organization_id => GlobalModelConfig.current_organization_id,
      :external => false
    )
  }
  scope :external_audit, lambda {
    where(
      :organization_id => GlobalModelConfig.current_organization_id,
      :external => true
    )
  }
  
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
  has_many :business_units, :dependent => :destroy, :order => 'name ASC'
  has_many :plan_items, :through => :business_units, :uniq => true

  accepts_nested_attributes_for :business_units, :allow_destroy => true

  def initialize(attributes = nil, options = {})
    super(attributes, options)

    self.organization_id = GlobalModelConfig.current_organization_id
  end

  def can_be_destroyed?
    self.business_units.all?(&:can_be_destroyed?)
  end
end