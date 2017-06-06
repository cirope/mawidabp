class FindingAnswer < ApplicationRecord
  include Auditable
  include FindingAnswers::DateColumns
  include FindingAnswers::Defaults
  include FindingAnswers::File
  include FindingAnswers::Notifications
  include FindingAnswers::Validations
  include ParameterSelector

  attr_readonly :answer, :file_model_id, :finding_id, :user_id, :created_at

  belongs_to :finding
  belongs_to :user, -> { where users: { hidden: [true, false] } }, optional: true
end
