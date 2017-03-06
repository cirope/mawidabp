class Poll < ApplicationRecord
  include Auditable
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
  # TODO: put optional: true on Rails 5 migration
  belongs_to :affected_user, class_name: 'User'
  belongs_to :organization
end
