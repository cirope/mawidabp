class Tag < ActiveRecord::Base
  include Auditable
  include Trimmer
  include Tags::Options
  include Tags::Scopes
  include Tags::Validation

  trimmed_fields :name

  belongs_to :organization

  def to_s
    name
  end
end
