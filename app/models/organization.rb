class Organization < ActiveRecord::Base
  include ParameterSelector
  include Trimmer

  trimmed_fields :name, :prefix
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Constantes
  INVALID_PREFIXES = ['www', APP_ADMIN_PREFIX]

  # Asociaciones que deben ser registradas cuando cambien
  @@associations_attributes_for_log = [:business_unit_ids, :parameter_ids]

  # Callbacks
  after_create :create_initial_data
  
  # Named scopes
  named_scope :list, :order => 'name ASC'

  # Atributos de solo lectura
  attr_readonly :group_id

  # Atributos no persistentes
  attr_accessor :must_create_parameters, :must_create_roles
  
  # Restricciones
  validates_format_of :prefix, :with => /\A[A-Za-z][A-Za-z0-9\-]+\z/,
    :allow_nil => true, :allow_blank => true
  validates_presence_of :name, :prefix
  validates_length_of :name, :prefix, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  validates_uniqueness_of :prefix, :case_sensitive => false
  validates_uniqueness_of :name, :case_sensitive => false, :scope => :group_id
  validates_exclusion_of :prefix, :in => INVALID_PREFIXES
  validates_each :business_units do |record, attr, value|
    unless value.all? {|bu| !bu.marked_for_destruction? || bu.can_be_destroyed?}
      record.errors.add attr, :locked
    end
  end
  
  # Relaciones
  belongs_to :group
  belongs_to :image_model, :dependent => :destroy
  has_many :business_units, :dependent => :destroy, :order => 'name ASC'
  has_many :parameters, :dependent => :destroy
  has_many :roles, :dependent => :destroy
  has_many :organization_roles, :dependent => :destroy
  has_many :users, :through => :organization_roles, :readonly => true

  accepts_nested_attributes_for :image_model, :allow_destroy => true
  accepts_nested_attributes_for :business_units, :allow_destroy => true,
    :reject_if => lambda { |attributes| attributes['name'].blank? }

  def initialize(attributes = nil)
    super(attributes)

    if Organization.exists?(GlobalModelConfig.current_organization_id)
      self.group_id = Organization.find(
        GlobalModelConfig.current_organization_id).group_id
    end
  end
  
  # Crea la configuración inicial de la organización
  def create_initial_data
    create_initial_parameters if must_create_parameters
    create_initial_roles if must_create_roles
  end

  private
  
  def create_initial_parameters
    DEFAULT_PARAMETERS.each do |name, value|
      self.parameters.build(
        :name => name.to_s,
        :value => value,
        :description => nil
      )
    end
  end

  def create_initial_roles
    Role.transaction do
      Role::TYPES.each do |type, value|
        role = self.roles.build(:name => "#{type}_#{self.prefix}",
          :role_type => value)

        role.inject_auth_privileges(Hash.new(Hash.new(true)))

        ALLOWED_MODULES_BY_TYPE[type].each do |mod|
          role.privileges.build(
            :module => mod.to_s,
            :read => true,
            :modify => true,
            :erase => true,
            :approval => true
          )
        end
      end
    end
  end
end