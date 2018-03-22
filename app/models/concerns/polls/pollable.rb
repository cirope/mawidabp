module Polls::Pollable
  extend ActiveSupport::Concern

  included do
    belongs_to :pollable, polymorphic: true, optional: true

    has_one :poll, class_name: 'Poll', foreign_key: :id # Self reference
    has_one :conclusion_review, through: :poll, source: :pollable, source_type: 'ConclusionReview'
  end
end
