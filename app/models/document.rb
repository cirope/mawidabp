class Document < ApplicationRecord
  include ActiveStorage::HasOneFile
  include Auditable
  include Documents::AttributeTypes
  include Documents::Defaults
  include Documents::FileModel
  include Documents::Scopes
  include Documents::Search
  include Documents::Shared
  include Documents::Validation
  include Shareable
  include Taggable
  include Trimmer

  trimmed_fields :name

  belongs_to :group
  belongs_to :organization

  def to_s
    name
  end
end
