module ConclusionReviews::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :issue_date, :date
    attribute :close_date, :date
    attribute :previous_date, :date
    attribute :approved, :boolean
    attribute :affects_compliance, :boolean
    attribute :collapse_control_objectives, :boolean
  end
end
