module Taggings::Associations
  extend ActiveSupport::Concern

  included do
    belongs_to :document, -> { where taggings: { taggable_type: 'Document' } }, foreign_key: 'taggable_id', optional: true
  end
end
