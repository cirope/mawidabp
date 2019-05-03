module OpeningInterviews::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :interview_date, :date
    attribute :start_date, :date
    attribute :end_date, :date
  end
end
