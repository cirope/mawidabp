class ResourceClass < ActiveRecord::Base
  include Auditable
  include ParameterSelector
  include ResourceClasses::Scopes
  include ResourceClasses::Validations
  include ResourceClasses::Resources
  include Trimmer

  attr_readonly :resource_class_type

  trimmed_fields :name

  belongs_to :organization

  def to_s
    name
  end
end
