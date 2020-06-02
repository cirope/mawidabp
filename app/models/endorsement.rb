class Endorsement < ApplicationRecord
  include Auditable
  include Endorsements::Defaults
  include Endorsements::Notifications
  include Endorsements::Status
  include Endorsements::Validation

  belongs_to :user
  belongs_to :finding_answer, touch: true

  has_one :finding, through: :finding_answer
  has_one :organization, through: :finding
end
