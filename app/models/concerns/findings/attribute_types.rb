module Findings::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :solution_date, :date
    attribute :follow_up_date, :date
    attribute :first_notification_date, :date
    attribute :last_notification_date, :date
    attribute :confirmation_date, :date
    attribute :origination_date, :date
    attribute :first_follow_up_date, :date
    attribute :implemented_at, :date
    attribute :closed_at, :date
    attribute :final, :boolean
    attribute :current_situation_verified, :boolean
  end
end
