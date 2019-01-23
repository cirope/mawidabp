module OpeningInterviews::Search
  extend ActiveSupport::Concern

  included do
    COLUMNS_FOR_SEARCH = {
      interview_date: interview_date_options,
      start_date:     start_date_options,
      end_date:       end_date_options,
      review:         review_options,
      project:        project_options
    }.with_indifferent_access
  end

  module ClassMethods
    private

      def interview_date_options
        date_column_options_for "#{quoted_table_name}.#{qcn 'interview_date'}"
      end

      def start_date_options
        date_column_options_for "#{quoted_table_name}.#{qcn 'start_date'}"
      end

      def end_date_options
        date_column_options_for "#{quoted_table_name}.#{qcn 'end_date'}"
      end

      def review_options
        string_column_options_for "#{Review.quoted_table_name}.#{Review.qcn 'identification'}"
      end

      def project_options
        string_column_options_for "#{PlanItem.quoted_table_name}.#{PlanItem.qcn 'project'}"
      end

      def date_column_options_for column
        {
          column:            column,
          operator:          SEARCH_ALLOWED_OPERATORS.values,
          mask:              "%s",
          conversion_method: ->(value) { Timeliness.parse(value, :date).to_s :db },
          regexp:            SEARCH_DATE_REGEXP
        }
      end

      def string_column_options_for column
        {
          column:            "LOWER(#{column})",
          operator:          'LIKE',
          mask:              "%%%s%%",
          conversion_method: :to_s,
          regexp:            /.*/
        }
      end
  end
end
