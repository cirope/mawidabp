# -*- coding: utf-8 -*-
class Role < ActiveRecord::Base
  include Comparable
  include ParameterSelector

  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Constantes
  TYPES = {
    :admin => 0,
    :manager => 1,
    :supervisor => 2,
    :auditor_senior => 3,
    :auditor_junior => 4,
    :committee => 5,
    :audited => 6,
    :executive_manager => 7
  }

  # Named scopes
  scope :list, ->(organization_id) {
    where(
      :organization_id =>
        organization_id || GlobalModelConfig.current_organization_id
    ).order('name ASC')
  }
  scope :list_by_organization_and_group, ->(organization, group) {
    includes(:organization).where(
      "#{table_name}.organization_id" => organization.id,
      "#{Organization.table_name}.group_id" => group.id
    )
  }

  # Callbacks
  before_validation :check_auth_privileges
  before_save :check_change_in_privileges

  # Restricciones
  validates :name, :format => {:with => /\A\w[\w\s-]*\z/},
    :allow_nil => true, :allow_blank => true
  validates :name, :organization_id, :role_type, :presence => true
  validates :name, :length => {:maximum => 255}, :allow_nil => true,
    :allow_blank => true
  validates :role_type, :inclusion => {:in => TYPES.values}, :allow_nil => true,
    :allow_blank => true
  validates :organization_id, :numericality => {:integer_only => true},
    :allow_nil => true, :allow_blank => true
  validates :name, :uniqueness =>
    {:case_sensitive => false, :scope => :organization_id}

  # Relaciones
  belongs_to :organization
  has_many :organization_roles, :dependent => :destroy
  has_many :privileges, :after_add => :assign_role, :dependent => :destroy
  has_many :users, -> { readonly }, :through => :organization_roles

  accepts_nested_attributes_for :privileges, :allow_destroy => true

  def initialize(attributes = nil, options = {})
    super(attributes, options)

    self.role_type ||= TYPES[:admin]
  end

  def assign_role(privilege)
    privilege.role = self
  end

  def <=>(other)
    other.kind_of?(Role) ? self.role_type <=> other.role_type : -1
  end

  def check_change_in_privileges
    self.touch if !self.new_record? && self.privileges.any?(&:changed?)
  end

  # Definición dinámica de todos los métodos "tipo?"
  TYPES.each do |type, value|
    define_method(:"#{type}?") { self.role_type == value }
  end

  def get_type
    TYPES.invert[self.role_type]
  end

  def allowed_modules
    get_type ? ALLOWED_MODULES_BY_TYPE[get_type] : []
  end

  def inject_auth_privileges(auth_privileges)
    if auth_privileges
      @auth_privileges = Marshal::load(Marshal::dump(auth_privileges))
    end
  end

  def check_auth_privileges
    unless self.has_auth_privileges?
      raise 'Must inject the auth privileges before save a Role'
    end
  end

  def has_auth_privileges?
    !@auth_privileges.nil?
  end

  def auth_privileges_for(module_name)
    module_name = '_' if module_name.blank?

    @auth_privileges[module_name] || @auth_privileges[module_name.to_sym] || {}
  end

  def privileges_hash
    privileges = HashWithIndifferentAccess.new

    self.privileges.each do |p|
      privileges[p.module] = {
        :read => p.read?,
        :modify => p.modify?,
        :erase => p.erase?,
        :approval => p.approval?
      }
    end

    privileges
  end

  def has_privilege_for?(module_name)
    self.privileges.any? do |p|
      p.module.to_sym == module_name.to_sym &&
        (p.read? || p.modify? || p.erase? || p.approval?)
    end
  end

  [:read, :modify, :erase, :approval].each do |action|
    define_method :"has_privilege_for_#{action}?" do |module_name|
      self.privileges.any? do |p|
        p.module.to_sym == module_name.to_sym && p.send(:"#{action}?")
      end
    end
  end
end
