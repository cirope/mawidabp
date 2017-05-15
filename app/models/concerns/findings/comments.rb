module Findings::Comments
  extend ActiveSupport::Concern

  included do
    has_many :comments, -> { order created_at: :asc }, as: :commentable, dependent: :destroy

    accepts_nested_attributes_for :comments, allow_destroy: false
  end
end
