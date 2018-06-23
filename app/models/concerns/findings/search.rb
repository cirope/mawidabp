module Findings::Search
  extend ActiveSupport::Concern

  included do
    COLUMNS_FOR_SEARCH = {
      issue_date:   issue_date_options,
      organization: organization_options,
      review:       review_options,
      project:      project_options,
      review_code:  review_code_options,
      title:        title_options,
      tags:         tags_options,
      updated_at:   updated_at_options
    }.with_indifferent_access
  end

  module ClassMethods
    private

      def issue_date_options
        date_column_options_for "#{ConclusionReview.table_name}.#{ConclusionReview.qcn('issue_date')}"
      end

      def updated_at_options
        date_column_options_for "#{quoted_table_name}.#{qcn('updated_at')}"
      end

      def date_column_options_for(column)
        {
          column:            column,
          operator:          SEARCH_ALLOWED_OPERATORS.values,
          mask:              "%s",
          conversion_method: ->(value) { Timeliness.parse(value, :date).to_s(:db) },
          regexp:            SEARCH_DATE_REGEXP
        }
      end

      def organization_options
        string_column_options_for "#{Organization.quoted_table_name}.#{Organization.qcn('prefix')}"
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

      def tags_options
        string_column_options_for "#{Tag.quoted_table_name}.#{Tag.qcn 'name'}"
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
