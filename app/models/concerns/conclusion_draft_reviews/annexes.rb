# frozen_string_literal: true

module ConclusionDraftReviews::Annexes
  extend ActiveSupport::Concern

  included do
    has_many :annexes, foreign_key: 'conclusion_review_id'

    accepts_nested_attributes_for :annexes, allow_destroy: true
  end
end
