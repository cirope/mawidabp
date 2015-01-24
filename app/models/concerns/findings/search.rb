module Findings::Search
  extend ActiveSupport::Concern

  included do
    COLUMNS_FOR_SEARCH = {
      issue_date:  issue_date_options,
      review:      review_options,
      project:     project_options,
      review_code: review_code_options,
      title:       title_options
    }.with_indifferent_access
  end

  module ClassMethods
    private

      def issue_date_options
        {
          column:            "#{ConclusionReview.table_name}.issue_date",
          operator:          SEARCH_ALLOWED_OPERATORS.values,
          mask:              "%s",
          conversion_method: ->(value) { Timeliness.parse(value, :date).to_s(:db) },
          regexp:            SEARCH_DATE_REGEXP
        }
      end

      def review_options
        string_column_options_for "#{Review.table_name}.identification"
      end

      def project_options
        string_column_options_for "#{PlanItem.table_name}.project"
      end

      def review_code_options
        string_column_options_for "#{table_name}.review_code"
      end

      def title_options
        string_column_options_for "#{table_name}.title"
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
