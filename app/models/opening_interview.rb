class OpeningInterview < ApplicationRecord
  include Auditable
  include OpeningInterviews::AttributeTypes
  include OpeningInterviews::DestroyValidation
  include OpeningInterviews::PDF
  include OpeningInterviews::UpdateCallbacks
  include OpeningInterviews::Users
  include OpeningInterviews::Search
  include OpeningInterviews::Scopes
  include OpeningInterviews::Validations

  belongs_to :organization
  belongs_to :review, optional: true
end
