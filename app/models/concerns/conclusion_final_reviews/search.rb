module ConclusionFinalReviews::Search
  extend ActiveSupport::Concern

  included do
    COLUMNS_FOR_SEARCH = {
      close_date: close_date_search_options 
    }.merge(ConclusionReview::GENERIC_COLUMNS_FOR_SEARCH).with_indifferent_access
  end

  module ClassMethods

    private

      def close_date_search_options
        {
          column:            "#{table_name}.#{qcn('close_date')}",
          mask:              '%s',
          regexp:            SEARCH_DATE_REGEXP,
          operator:          SEARCH_ALLOWED_OPERATORS.values,
          conversion_method: -> (value) { Timeliness.parse(value, :date).to_s :db }
        }
      end
  end
end
