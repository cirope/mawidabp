class Parameter < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new {GlobalModelConfig.current_organization_id},
    :important => Proc.new {|parameter| parameter.name.starts_with?('security')}
  }

  serialize :value

  # Named scopes
  # Deprecated
  scope :all_parameters, lambda { |name|
    where(
      :organization_id => GlobalModelConfig.current_organization_id,
      :name => name.to_s
    )
  }

  # Restricciones de los atributos
  attr_readonly :name
  
  # Restricciones
  validates :name, :format => {:with => /\A\w+\z/},
    :allow_nil => true, :allow_blank => true
  validates :name, :value, :organization_id, :presence => true
  validates :name, :length => {:maximum => 100}, :allow_nil => true,
    :allow_blank => true
  validates :name, :uniqueness =>
    {:case_sensitive => false, :scope => :organization_id}

  # Relaciones
  belongs_to :organization

  def to_s
    I18n.t self.name, :scope => :parameter
  end

  def self.find_parameter(organization_id, name, version = nil)
    parameter = Parameter.where(
      :name => name.to_s, :organization_id => organization_id
    ).first.try(:version_of, version)

    parameter.try(:value) || DEFAULT_PARAMETERS[name]
  end
end