class Tag < ActiveRecord::Base
  include Auditable
  include Trimmer
  include Tags::JSON
  include Tags::Options
  include Tags::Scopes
  include Tags::Validation

  trimmed_fields :name

  belongs_to :organization
  has_many :taggings, dependent: :restrict_with_error

  def to_s
    name
  end
end
