class User < ApplicationRecord
  include ActsAsTree
  include Comparable
  include ParameterSelector
  include Trimmer
  include Users::AttributeTypes
  include Users::Auditable
  include Users::Authorization
  include Users::CloseDateWarning
  include Users::CustomAttributes
  include Users::Defaults
  include Users::DestroyValidation
  include Users::Findings
  include Users::Group
  include Users::MarkChanges
  include Users::Name
  include Users::Notifications
  include Users::Password
  include Users::Polls
  include Users::Reassigns
  include Users::Relations
  include Users::Releases
  include Users::Resources
  include Users::ReviewAssignment
  include Users::Roles
  include Users::Scopes
  include Users::Search
  include Users::BaseValidations
  include Users::Validations
  include Users::Tree

  trimmed_fields :user, :email, :name, :last_name

  has_many :login_records, dependent: :destroy
  has_many :error_records, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :review_user_assignments, dependent: :destroy
  has_many :reviews, through: :review_user_assignments
  has_many :conclusion_final_reviews, through: :reviews

  def <=>(other)
    other.kind_of?(User) ? id <=> other.id : -1
  end

  def to_s
    user
  end

  def to_param
    "#{id}-#{user}".parameterize
  end
end
