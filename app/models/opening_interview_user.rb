class OpeningInterviewUser < ApplicationRecord
  include Auditable

  validates :opening_interview, :user, presence: true

  belongs_to :opening_interview
  belongs_to :user, optional: true
end
