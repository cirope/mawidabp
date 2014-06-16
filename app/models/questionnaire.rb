class Questionnaire < ActiveRecord::Base
  include Auditable
  include Questionnaires::Validations
  include Questionnaires::Scopes
  include Questionnaires::Polls
  include Questionnaires::Questions
  include Questionnaires::Answers

  POLLABLE_TYPES = ['ConclusionReview']

  belongs_to :organization
end
