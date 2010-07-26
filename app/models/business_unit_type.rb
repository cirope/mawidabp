class BusinessUnitType < ActiveRecord::Base
  include Trimmer

  trimmed_fields :name, :business_unit_label, :project_label

  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Named scopes
  named_scope :list, proc {
    {
      :conditions => {
        :organization_id => GlobalModelConfig.current_organization_id
      },
      :order => ['external ASC', 'name ASC'].join(', ')
    }
  }
  
  # Restricciones
  validates_presence_of :name, :business_unit_label
  validates_length_of :name, :business_unit_label, :project_label,
    :maximum => 255, :allow_nil => true, :allow_blank => true
  validates_uniqueness_of :name, :case_sensitive => false,
    :scope => :organization_id
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

  accepts_nested_attributes_for :business_units, :allow_destroy => true

  def initialize(attributes = nil)
    super(attributes)

    self.organization_id = GlobalModelConfig.current_organization_id
  end

  def can_be_destroyed?
    self.business_units.all?(&:can_be_destroyed?)
  end
end