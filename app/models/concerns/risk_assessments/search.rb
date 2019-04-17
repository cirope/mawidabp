module RiskAssessments::Search
  extend ActiveSupport::Concern

  included do
    COLUMNS_FOR_SEARCH = {
      period:      period_options,
      name:        name_options,
      description: description_options
    }.with_indifferent_access
  end

  module ClassMethods
    private

      def period_options
        string_column_options_for "#{Period.quoted_table_name}.#{Period.qcn 'name'}"
      end

      def name_options
        string_column_options_for "#{quoted_table_name}.#{qcn 'name'}"
      end

      def description_options
        string_column_options_for "#{quoted_table_name}.#{qcn 'description'}"
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
