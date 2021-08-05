class Annex < ApplicationRecord
  include Annexes::ImageModels
  include Annexes::Validation

  belongs_to :conclusion_draft_review, foreign_key: 'conclusion_review_id'

  def to_s
    title
  end
end
