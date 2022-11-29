# frozen_string_literal: true

class Annex < ApplicationRecord
  include ActiveStorage::HasManyImages
  include Annexes::ImageModels
  include Annexes::Validation

  belongs_to :conclusion_review

  def to_s
    title
  end
end
