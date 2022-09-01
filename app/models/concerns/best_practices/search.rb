module BestPractices::Search
  extend ActiveSupport::Concern
  include Searchable

  included do
    COLUMNS_FOR_SEARCH = {
      name: {
        column: "LOWER(#{quoted_table_name}.#{qcn 'name'})"
      }
    }.with_indifferent_access
  end
end
