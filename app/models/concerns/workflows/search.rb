module Workflows::Search
  extend ActiveSupport::Concern
  include Searchable

  included do
    COLUMNS_FOR_SEARCH = {
      review:  review_options,
      project: project_options
    }.with_indifferent_access
  end

  module ClassMethods
    private

    def review_options
      string_column_options_for "#{Review.quoted_table_name}.#{Review.qcn('identification')}"
    end

    def project_options
      string_column_options_for "#{PlanItem.quoted_table_name}.#{PlanItem.qcn('project')}"
    end

    def string_column_options_for column
      {
        column:            "LOWER(#{column})",
        operator:          'LIKE',
        mask:              '%%%s%%',
        conversion_method: :to_s,
        regexp:            /.*/
      }
    end
  end
end
