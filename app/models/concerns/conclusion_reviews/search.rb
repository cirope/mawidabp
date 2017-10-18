module ConclusionReviews::Search
  extend ActiveSupport::Concern

  included do
    GENERIC_COLUMNS_FOR_SEARCH = ActiveSupport::HashWithIndifferentAccess.new(
      issue_date:     issue_date_options,
      period:         period_options,
      identification: identification_options,
      summary:        summary_options,
      business_unit:  business_unit_options,
      project:        project_options
    )
  end

  module ClassMethods
    private

      def issue_date_options
        {
          column:            "#{quoted_table_name}.#{qcn 'issue_date'}",
          mask:              '%s',
          operator:          SEARCH_ALLOWED_OPERATORS.values,
          regexp:            SEARCH_DATE_REGEXP,
          conversion_method: -> (value) { Timeliness.parse(value, :date).to_s :db }
        }
      end

      def period_options
        string_column_options_for "#{Period.quoted_table_name}.#{Period.qcn 'name'}"
      end

      def identification_options
        string_column_options_for "#{Review.quoted_table_name}.#{Review.qcn 'identification'}"
      end

      def summary_options
        string_column_options_for "#{quoted_table_name}.#{qcn 'summary'}"
      end

      def business_unit_options
        string_column_options_for "#{BusinessUnit.quoted_table_name}.#{BusinessUnit.qcn 'name'}"
      end

      def project_options
        string_column_options_for "#{PlanItem.quoted_table_name}.#{PlanItem.qcn 'project'}"
      end

      def string_column_options_for column
        {
          column:            "LOWER(#{column})",
          mask:              '%%%s%%',
          operator:          'LIKE',
          regexp:            /.*/,
          conversion_method: :to_s
        }
      end
  end
end
