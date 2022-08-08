module Memos::Search
  extend ActiveSupport::Concern
  include Searchable

  included do
    COLUMNS_FOR_SEARCH = {
      name: {
        column: "LOWER(#{Memo.quoted_table_name}.#{Memo.qcn 'name'})"
      }
    }.with_indifferent_access
  end
end
