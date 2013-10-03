class Organization < ActiveRecord::Base
  include ParameterSelector
  include Trimmer
  include Comparable

  trimmed_fields :name, :prefix

  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Constantes
  INVALID_PREFIXES = ['www', APP_ADMIN_PREFIX]

  # Callbacks
  before_save :change_current_organization_id
  after_create :create_initial_data
  after_save :restore_current_organization_id
  before_destroy :can_be_destroyed?
  after_destroy :destroy_image_model # TODO: delete when Rails fix gets in stable

  # Named scopes
  scope :list, -> { order('name ASC') }
  scope :list_for_group, ->(group) { where(:group_id => group.id) }

  # Atributos de solo lectura
  attr_readonly :group_id

  # Atributos no persistentes
  attr_accessor :must_create_parameters, :must_create_roles

  # Restricciones
  validates :prefix, :format => {:with => /\A[A-Za-z][A-Za-z0-9\-]+\z/},
    :allow_nil => true, :allow_blank => true
  validates :name, :prefix, :kind, :presence => true
  validates :name, :prefix, :length => {:maximum => 255}, :allow_nil => true,
    :allow_blank => true
  validates :prefix, :uniqueness => {:case_sensitive => false}
  validates :name, :uniqueness =>
    {:case_sensitive => false, :scope => :group_id}
  validates :prefix, :exclusion => {:in => INVALID_PREFIXES}
  validates :kind, :inclusion => {:in => ORGANIZATION_KINDS}, :allow_nil => true,
    :allow_blank => true

  # Relaciones
  belongs_to :group
  belongs_to :image_model
  has_many :business_unit_types, -> { order('name ASC') },
    :dependent => :destroy
  has_many :parameters, :dependent => :destroy
  has_many :roles, :dependent => :destroy
  has_many :organization_roles, :dependent => :destroy
  has_many :best_practices, :dependent => :destroy
  has_many :login_records, :dependent => :destroy
  has_many :error_records, :dependent => :destroy
  has_many :work_papers, :dependent => :destroy
  has_many :periods, :dependent => :destroy
  has_many :resource_classes, :dependent => :destroy
  has_many :detracts, :dependent => :destroy
  has_many :polls, :dependent => :destroy
  has_many :questionnaires, :dependent => :destroy
  has_many :users, -> { readonly.uniq }, :through => :organization_roles

  accepts_nested_attributes_for :image_model, :allow_destroy => true,
    :reject_if => lambda { |attributes| attributes['image'].blank? }

  def initialize(attributes = nil, options = {})
    super(attributes, options)

    if GlobalModelConfig.current_organization_id &&
        Organization.exists?(GlobalModelConfig.current_organization_id)
      self.group_id = Organization.find(
        GlobalModelConfig.current_organization_id).group_id
    end
  end

  def <=>(other)
    self.prefix <=> other.prefix
  end

  # Crea la configuración inicial de la organización
  def create_initial_data
    create_initial_parameters if must_create_parameters
    create_initial_roles if must_create_roles
  end

  def self.all_parameters(param_name)
    self.all.map do |o|
      {
        :organization => o,
        :parameter => Parameter.find_parameter(o.id, param_name)
      }
    end
  end

  def change_current_organization_id
    @_current_organization_id = GlobalModelConfig.current_organization_id
    GlobalModelConfig.current_organization_id = self.id if self.id
  end

  def restore_current_organization_id
    GlobalModelConfig.current_organization_id = @_current_organization_id
  end

  def can_be_destroyed?
    unless best_practices.all?(&:can_be_destroyed?)
      _errors = best_practices.map do |bp|
        bp.errors.full_messages.join(APP_ENUM_SEPARATOR)
      end

      errors.add :base, _errors.reject(&:blank?).join(APP_ENUM_SEPARATOR)

      false
    else
      true
    end
  end

  def destroy_image_model
    image_model.try(:destroy!)
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
