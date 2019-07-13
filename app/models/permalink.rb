class Permalink < ApplicationRecord
  include Auditable
  include Permalinks::Defaults
  include Permalinks::Options
  include Permalinks::Scopes
  include Permalinks::Validation

  belongs_to :organization
  has_many :permalink_models, dependent: :destroy

  def to_param
    persisted? ? token : nil
  end
end
