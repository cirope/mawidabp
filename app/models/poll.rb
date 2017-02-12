class Poll < ActiveRecord::Base
  include Auditable
  include Polls::Search
  include Polls::Validations
  include Polls::Scopes
  include Polls::AccessToken
  include Polls::SendEmail
  include Polls::Defaults

  attr_accessor :customer_name

  belongs_to :questionnaire
  belongs_to :user
  # TODO: put optional: true on Rails 5 migration
  belongs_to :affected_user, class_name: 'User'
  belongs_to :organization
  belongs_to :pollable, polymorphic: true
  has_many :answers, -> {
    includes(:question).order("#{Question.quoted_table_name}.#{Question.qcn('sort_order')} ASC").
    references(:questions)
  }, dependent: :destroy
  accepts_nested_attributes_for :answers
end
