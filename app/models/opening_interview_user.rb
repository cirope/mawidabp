class OpeningInterviewUser < ApplicationRecord
  include Auditable

  enum kind: {
    responsible: 'responsible',
    auditor:     'auditor',
    assistant:   'assistant'
  }

  validates :user, presence: true

  belongs_to :opening_interview, optional: true
  belongs_to :user, optional: true
end
