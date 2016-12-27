module ConclusionReviews::DateColumns
  extend ActiveSupport::Concern

  included do
    if ActiveRecord::ConnectionAdapters.const_defined?(:OracleEnhancedAdapter)
      set_date_columns :issue_date, :close_date
    end
  end
end
