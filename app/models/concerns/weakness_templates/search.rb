module WeaknessTemplates::Search
  extend ActiveSupport::Concern

  included do
    COLUMNS_FOR_SEARCH = {
      title: title_options,
      description: description_options
    }.with_indifferent_access
  end

  module ClassMethods
    private

    def title_options
      string_column_options_for "#{quoted_table_name}.#{qcn 'title'}"
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
