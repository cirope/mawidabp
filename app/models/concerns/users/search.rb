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

    if POSTGRESQL_ADAPTER
      COLUMNS_FOR_SEARCH.merge!(
        tags: {
          column: "LOWER(#{Tag.quoted_table_name}.#{Tag.qcn 'name'})"
        }
      ).with_indifferent_access
    end
  end
end
