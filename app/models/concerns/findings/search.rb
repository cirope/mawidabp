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
          column:            "#{ConclusionReview.table_name}.#{ConclusionReview.qcn('issue_date')}",
          operator:          SEARCH_ALLOWED_OPERATORS.values,
          mask:              "%s",
          conversion_method: ->(value) { Timeliness.parse(value, :date).to_s(:db) },
          regexp:            SEARCH_DATE_REGEXP
        }
      end

      def review_options
        string_column_options_for "#{Review.quoted_table_name}.#{Review.qcn('identification')}"
      end

      def project_options
        string_column_options_for "#{PlanItem.quoted_table_name}.#{PlanItem.qcn('project')}"
      end

      def review_code_options
        string_column_options_for "#{quoted_table_name}.#{qcn('review_code')}"
      end

      def title_options
        string_column_options_for "#{quoted_table_name}.#{qcn('title')}"
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
