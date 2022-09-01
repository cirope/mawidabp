module OpeningInterviews::Search
  extend ActiveSupport::Concern
  include Searchable

  included do
    COLUMNS_FOR_SEARCH = {
      interview_date: date_column_options_for(
        "#{quoted_table_name}.#{qcn 'interview_date'}"
      ),
      start_date: date_column_options_for(
        "#{quoted_table_name}.#{qcn 'start_date'}"
      ),
      end_date: date_column_options_for(
        "#{quoted_table_name}.#{qcn 'end_date'}"
      ),
      review: {
        column: "LOWER(#{Review.quoted_table_name}.#{Review.qcn 'identification'})"
      },
      project: {
        column: "LOWER(#{Review.quoted_table_name}.#{Review.qcn 'identification'})"
      }
    }.with_indifferent_access
  end
end
