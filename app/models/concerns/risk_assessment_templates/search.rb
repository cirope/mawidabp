module RiskAssessmentTemplates::Search
  extend ActiveSupport::Concern

  included do
    COLUMNS_FOR_SEARCH = {
      name:        name_options,
      description: description_options
    }.with_indifferent_access
  end

  module ClassMethods
    private

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
