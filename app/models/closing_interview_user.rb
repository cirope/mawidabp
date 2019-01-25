class ClosingInterviewUser < ApplicationRecord
  include Auditable

  validates :closing_interview, :user, presence: true

  belongs_to :closing_interview
  belongs_to :user, optional: true
end
