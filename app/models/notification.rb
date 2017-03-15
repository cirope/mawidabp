class Notification < ApplicationRecord
  include Comparable
  include Notifications::Status
  include Notifications::Defaults
  include Notifications::Notify
  include Notifications::Validation

  belongs_to :user
  belongs_to :user_who_confirm, class_name: 'User'
  has_many :notification_relations, dependent: :destroy
  has_many :findings, through: :notification_relations,
    source: :model, source_type: 'Finding'
  has_many :conclusion_reviews, through: :notification_relations,
    source: :model, source_type: 'ConclusionReview'

  def <=> other
    other.kind_of?(Notification) ? id <=> other.id : -1
  end

  def to_param
    confirmation_hash
  end
end
