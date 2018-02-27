class Reading < ApplicationRecord
  scope :list, -> { where organization_id: Organization.current_id }

  validates :user, :readable, presence: true
  validates :readable_type, inclusion: { in: %w(FindingAnswer) }

  belongs_to :user
  belongs_to :organization
  belongs_to :readable, polymorphic: true
end
