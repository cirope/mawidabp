class FindingAnswer < ApplicationRecord
  include Auditable
  include FindingAnswers::CommitmentDate
  include FindingAnswers::DateColumns
  include FindingAnswers::Defaults
  include FindingAnswers::File
  include FindingAnswers::Notifications
  include FindingAnswers::Readings
  include FindingAnswers::Scopes
  include FindingAnswers::Validations
  include ParameterSelector

  attr_readonly :answer, :file_model_id, :finding_id, :user_id, :created_at

  belongs_to :finding, touch: true
  belongs_to :user, -> { where users: { hidden: [true, false] } }, optional: true
end
