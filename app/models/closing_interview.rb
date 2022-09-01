class ClosingInterview < ApplicationRecord
  include Auditable
  include ClosingInterviews::AttributeTypes
  include ClosingInterviews::DestroyValidation
  include ClosingInterviews::Pdf
  include ClosingInterviews::Scopes
  include ClosingInterviews::Search
  include ClosingInterviews::UpdateCallbacks
  include ClosingInterviews::Users
  include ClosingInterviews::Validations

  belongs_to :organization
  belongs_to :review, optional: true
end
