class Poll < ApplicationRecord
  include Auditable
  include Polls::About
  include Polls::AccessToken
  include Polls::Answers
  include Polls::AttributeTypes
  include Polls::Defaults
  include Polls::Pollable
  include Polls::Scopes
  include Polls::Search
  include Polls::SendEmail
  include Polls::Validations

  belongs_to :questionnaire
  belongs_to :user
  belongs_to :organization
end
