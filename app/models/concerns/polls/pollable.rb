module Polls::Pollable
  extend ActiveSupport::Concern

  included do
    belongs_to :pollable, polymorphic: true
    belongs_to :conclusion_review, -> {
      joins(:polls).where polls: { pollable_type: 'ConclusionReview' }
    }, foreign_key: 'pollable_id'
  end
end
