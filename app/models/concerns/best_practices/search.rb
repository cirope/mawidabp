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
      if query.present? && columns.any?
        where(
          *[prepare_search(raw_query: query, columns: columns)].flatten
        )
      else
        all
      end
    end
  end
end
