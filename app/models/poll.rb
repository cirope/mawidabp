class Poll < ApplicationRecord
  include Auditable
  include Polls::About
  include Polls::Answers
  include Polls::AccessToken
  include Polls::Defaults
  include Polls::Pollable
  include Polls::Scopes
  include Polls::Search
  include Polls::SendEmail
  include Polls::Validations

  belongs_to :questionnaire
  belongs_to :user
  # belongs_to :affected_user, class_name: 'User', optional: true
  belongs_to :organization
end
