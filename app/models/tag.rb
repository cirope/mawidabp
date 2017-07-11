class Tag < ApplicationRecord
  include Auditable
  include Trimmer
  include Shareable
  include Tags::Defaults
  include Tags::Icons
  include Tags::JSON
  include Tags::Kinds
  include Tags::Options
  include Tags::Scopes
  include Tags::Validation

  trimmed_fields :name

  belongs_to :organization
  belongs_to :group
  has_many :taggings, dependent: :restrict_with_error
  has_many :documents, through: :taggings

  def to_s
    name
  end
end
