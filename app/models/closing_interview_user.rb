class ClosingInterviewUser < ApplicationRecord
  include Auditable

  enum kind: {
    responsible: 'responsible',
    auditor:     'auditor',
    assistant:   'assistant'
  }

  validates :user, presence: true

  belongs_to :closing_interview, optional: true
  belongs_to :user, optional: true
end
