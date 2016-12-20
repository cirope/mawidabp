class Document < ActiveRecord::Base
  include Auditable
  include Documents::Shared
  include Documents::Defaults
  include Documents::FileModel
  include Documents::Scopes
  include Documents::Search
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
