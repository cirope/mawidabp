module Taggings::Validation
  extend ActiveSupport::Concern

  included do
    validates :tag, presence: :true
    validates :tag_id, uniqueness: { scope: [:taggable_id, :taggable_type] }
  end
end
