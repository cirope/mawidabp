class ResourceClass < ActiveRecord::Base
  include Auditable
  include Trimmer
  include ParameterSelector
  include ResourceClasses::Scopes
  include ResourceClasses::Validations
  include ResourceClasses::Resources

  attr_readonly :resource_class_type

  trimmed_fields :name

  belongs_to :organization

  def to_s
    name
  end
end
