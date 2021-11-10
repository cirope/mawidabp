# frozen_string_literal: true

module ConclusionReviews::Annexes
  extend ActiveSupport::Concern

  included do
    has_many :annexes, dependent: :destroy

    accepts_nested_attributes_for :annexes, allow_destroy: true
  end
end
