class News < ActiveRecord::Base
  include Auditable
  include News::Defaults
  include News::Scopes
  include News::Search
  include News::Validation
  include Shareable
  include Taggable
  include Trimmer

  trimmed_fields :title

  belongs_to :organization
  belongs_to :group

  def to_s
    title
  end

  def to_param
    "#{id}-#{title}".parameterize
  end
end
