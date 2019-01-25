module ClosingInterviews::Users
  extend ActiveSupport::Concern

  included do
    has_many :closing_interview_users, dependent: :destroy
    has_many :users, through: :closing_interview_users

    accepts_nested_attributes_for :closing_interview_users, allow_destroy: true
  end
end
