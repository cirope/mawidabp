class ResourceClass < ActiveRecord::Base
  include Auditable
  include ParameterSelector
  include ResourceClasses::Scopes
  include ResourceClasses::Validations
  include ResourceClasses::Resources
  include Trimmer

  trimmed_fields :name

  belongs_to :organization

  def to_s
    name
  end
end
