module OpeningInterviews::Users
  extend ActiveSupport::Concern

  included do
    has_many :responsibles, -> { responsible }, dependent: :destroy,
      class_name: 'OpeningInterviewUser'
    has_many :auditors, -> { auditor }, dependent: :destroy,
      class_name: 'OpeningInterviewUser'
    has_many :assistants, -> { assistant }, dependent: :destroy,
      class_name: 'OpeningInterviewUser'

    has_many :responsible_users, through: :responsibles, source: :user
    has_many :auditor_users, through: :auditors, source: :user
    has_many :assistant_users, through: :assistants, source: :user

    accepts_nested_attributes_for :responsibles, allow_destroy: true
    accepts_nested_attributes_for :auditors, allow_destroy: true
    accepts_nested_attributes_for :assistants, allow_destroy: true
  end
end
