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

  module ClassMethods
    def search query: nil, columns: []
      result = all

      if query.present? && columns.any?
        result = where(
          *[prepare_search(raw_query: query, columns: columns)].flatten
        )
      end

      result
    end
  end
end
