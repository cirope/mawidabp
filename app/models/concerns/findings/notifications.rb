module Findings::Notifications
  extend ActiveSupport::Concern

  included do
    has_many :notification_relations, as: :model, dependent: :destroy
    has_many :notifications, -> { order :created_at }, through: :notification_relations
  end
end
