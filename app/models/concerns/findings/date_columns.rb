module Findings::DateColumns
  extend ActiveSupport::Concern

  included do
    if ActiveRecord::ConnectionAdapters.const_defined?(:OracleEnhancedAdapter)
      set_date_columns :solution_date, :follow_up_date,
        :first_notification_date, :confirmation_date, :origination_date
    end
  end
end
