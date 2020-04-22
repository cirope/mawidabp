module NewsModule::Search
  extend ActiveSupport::Concern
  include Searchable

  included do
    COLUMNS_FOR_SEARCH = {
      title: {
        column: "LOWER(#{quoted_table_name}.#{qcn 'title'})"
      },
      tags: {
        column: "LOWER(#{Tag.quoted_table_name}.#{Tag.qcn 'name'})"
      }
    }.with_indifferent_access
  end
end
