module ClosingInterviews::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :interview_date, :date
  end
end
