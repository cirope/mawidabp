class ClosingInterview < ApplicationRecord
  include Auditable
  include ClosingInterviews::PDF
  include ClosingInterviews::Scopes
  include ClosingInterviews::Search
  include ClosingInterviews::Users
  include ClosingInterviews::Validations

  belongs_to :organization
  belongs_to :review, optional: true
end
