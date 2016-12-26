class Tagging < ActiveRecord::Base
  include Auditable
  include Taggings::Associations
  include Taggings::Scopes
  include Taggings::Validation

  belongs_to :tag
  belongs_to :taggable, polymorphic: true

  def to_s
    "#{tag} -> #{taggable}"
  end
end
