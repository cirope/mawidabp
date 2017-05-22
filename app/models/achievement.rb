class Achievement < ApplicationRecord
  include Auditable
  include Achievements::Validations

  delegate :benefit?, :damage?, to: :benefit

  belongs_to :benefit
  belongs_to :finding, optional: true

  def signed_amount
    benefit? ? amount : -amount
  end
end
