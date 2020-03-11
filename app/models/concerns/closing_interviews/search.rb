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
      project: {
        column: "LOWER(#{PlanItem.quoted_table_name}.#{PlanItem.qcn 'project'})"
      },
      review: {
        column: "LOWER(#{Review.quoted_table_name}.#{Review.qcn 'identification'})"
      }
    }.with_indifferent_access
  end
end
