class Annex < ApplicationRecord
  include Annexes::ImageModels
  include Annexes::Validation

  belongs_to :conclusion_review

  def to_s
    title
  end
end
