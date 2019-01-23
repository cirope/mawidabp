module OpeningInterviews::Users
  extend ActiveSupport::Concern

  included do
    has_many :opening_interview_users, dependent: :destroy
    has_many :users, through: :opening_interview_users

    accepts_nested_attributes_for :opening_interview_users, allow_destroy: true
  end
end
