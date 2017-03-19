module ConclusionReviews::DateColumns
  extend ActiveSupport::Concern

  included do
    attribute :issue_date, :date
    attribute :close_date, :date
  end
end
