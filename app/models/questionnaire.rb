class Questionnaire < ApplicationRecord
  include Auditable
  include Questionnaires::Answers
  include Questionnaires::Polls
  include Questionnaires::Questions
  include Questionnaires::Scopes
  include Questionnaires::Validations

  POLLABLE_TYPES = ['ConclusionReview']

  belongs_to :organization
end
