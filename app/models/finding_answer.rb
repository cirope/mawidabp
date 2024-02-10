class FindingAnswer < ApplicationRecord
  include Auditable
  include FindingAnswers::AttributeTypes
  include FindingAnswers::CommitmentDate
  include FindingAnswers::CommitmentSupport
  include FindingAnswers::Defaults
  include FindingAnswers::Endorsements
  include FindingAnswers::File
  include FindingAnswers::Notifications
  include FindingAnswers::Readings
  include FindingAnswers::Scopes
  include FindingAnswers::Validations
  include ParameterSelector

  attr_readonly :file_model_id, :created_at
  attr_accessor :finding_id

  belongs_to :finding, touch: true
  belongs_to :user, -> { where users: { hidden: [true, false] } }, optional: true

  def label
    [finding&.review&.identification, finding&.review_code].join ' | '
  end
end
