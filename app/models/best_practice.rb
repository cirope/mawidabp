class BestPractice < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Callbacks
  before_destroy :can_be_destroyed?

  # Named scopes
  scope :list, lambda {
    {
      :conditions => {
        :organization_id => GlobalModelConfig.current_organization_id
      },
      :order => 'name ASC'
    }
  }

  # Restricciones
  validates_presence_of :name, :organization_id
  validates_length_of :name, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  validates_numericality_of :organization_id, :only_integer => true,
    :allow_blank => true, :allow_nil => true
  validates_uniqueness_of :name, :case_sensitive => false,
    :scope => :organization_id
  validates_each :process_controls do |record, attr, value|
    unless value.all? {|pc| !pc.marked_for_destruction? || pc.can_be_destroyed?}
      record.errors.add attr, :locked
    end
  end
  
  # Relaciones
  belongs_to :organization
  has_many :process_controls, :dependent => :destroy,
    :after_add => :assign_best_practice,
    :order => "#{ProcessControl.table_name}.order ASC"
  
  accepts_nested_attributes_for :process_controls, :allow_destroy => true

  def initialize(attributes = nil)
    super(attributes)

    self.organization_id = GlobalModelConfig.current_organization_id
  end

  def assign_best_practice(process_control)
    process_control.best_practice = self
  end

  def can_be_destroyed?
    unless self.process_controls.all? {|pc| pc.can_be_destroyed?}
      errors = self.process_controls.map do |pc|
        pc.errors.full_messages.join(APP_ENUM_SEPARATOR)
      end
      
      self.errors.add :base, errors.reject { |e| e.blank? }.join(
        APP_ENUM_SEPARATOR)

      false
    else
      true
    end
  end
end