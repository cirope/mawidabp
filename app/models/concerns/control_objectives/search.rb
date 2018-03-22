module ControlObjectives::Search
  extend ActiveSupport::Concern

  included do
    COLUMNS_FOR_SEARCH = {
      best_practice: best_practice_options,
      name:          name_options
    }.with_indifferent_access
  end

  module ClassMethods
    private

      def best_practice_options
        string_column_options_for "#{BestPractice.quoted_table_name}.#{BestPractice.qcn 'name'}"
      end

      def name_options
        string_column_options_for "#{quoted_table_name}.#{qcn 'name'}"
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
