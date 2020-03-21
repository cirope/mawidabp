module Emails::Search
  extend ActiveSupport::Concern
  include Searchable

  included do
    COLUMNS_FOR_SEARCH = {
      to: {
        column: "LOWER(#{EMail.quoted_table_name}.#{EMail.qcn 'to'})"
      },
      subject: {
        column: "LOWER(#{EMail.quoted_table_name}.#{EMail.qcn 'subject'})"
      }
    }.with_indifferent_access
  end
end
