class OpeningInterview < ApplicationRecord
  include Auditable
  include OpeningInterviews::PDF
  include OpeningInterviews::Users
  include OpeningInterviews::Search
  include OpeningInterviews::Scopes
  include OpeningInterviews::Validations

  belongs_to :organization
  belongs_to :review, optional: true
end
