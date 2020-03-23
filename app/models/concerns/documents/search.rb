module Documents::Search
  extend ActiveSupport::Concern
  include Searchable

  included do
    COLUMNS_FOR_SEARCH = {
      name: {
        column: "LOWER(#{quoted_table_name}.#{qcn 'name'})"
      },
      description: {
        column: "LOWER(#{quoted_table_name}.#{qcn 'description'})"
      },
      tags: {
        column: "LOWER(#{Tag.quoted_table_name}.#{Tag.qcn 'name'})"
      }
    }.with_indifferent_access
  end
end
