class Resource < ApplicationRecord
  include Auditable
  include ParameterSelector
  include Resources::Validation
  include Trimmer

  belongs_to :resource_class, optional: true
  has_many :resource_utilizations, as: :resource, dependent: :destroy

  trimmed_fields :name, :description

  def to_s
    name
  end
  alias_method :resource_name, :to_s
end
