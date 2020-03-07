module ClosingInterviews::Search
  extend ActiveSupport::Concern
  include Searchable

  included do
    COLUMNS_FOR_SEARCH = {
      interview_date: {
        column:            "#{quoted_table_name}.#{qcn 'interview_date'}",
        operator:          SEARCH_ALLOWED_OPERATORS.values,
        mask:              '%s',
        conversion_method: ->(value) { Timeliness.parse(value, :date).to_s :db },
        regexp:            SEARCH_DATE_REGEXP
      },
      review:         {
        column: "LOWER(#{Review.quoted_table_name}.#{Review.qcn 'identification'})"
      },
      project:        {
        column: "LOWER(#{PlanItem.quoted_table_name}.#{PlanItem.qcn 'project'})"
      }
    }.with_indifferent_access
  end

  module ClassMethods
    def search query: nil, columns: []
      result = all

      if query.present? && columns.any?
        result = where(
          *[prepare_search(raw_query: query, columns: columns)].flatten
        )
      end

      result
    end
  end
end
