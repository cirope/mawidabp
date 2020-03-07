module Users::Search
  extend ActiveSupport::Concern
  include Searchable

  included do
    COLUMNS_FOR_SEARCH = {
      user: {
        column: "LOWER(#{quoted_table_name}.#{qcn 'user'})"
      },
      name: {
        column: "LOWER(#{quoted_table_name}.#{qcn 'name'})"
      },
      last_name: {
        column: "LOWER(#{quoted_table_name}.#{qcn 'last_name'})"
      },
      function: {
        column: "LOWER(#{quoted_table_name}.#{qcn 'function'})"
      }
    }.with_indifferent_access
  end

  module ClassMethods
    def search query: nil, columns: [], organization_id: Current.organization&.id
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
