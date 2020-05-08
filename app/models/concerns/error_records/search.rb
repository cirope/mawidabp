module ErrorRecords::Search
  extend ActiveSupport::Concern
  include Searchable

  included do
    COLUMNS_FOR_SEARCH = {
      user: {
        column: "LOWER(#{User.quoted_table_name}.#{User.qcn 'user'})"
      },
      data: {
        column: "LOWER(#{quoted_table_name}.#{qcn 'data'})"
      }
    }.with_indifferent_access
  end
end
