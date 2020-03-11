module ControlObjectives::Search
  extend ActiveSupport::Concern
  include Searchable

  included do
    COLUMNS_FOR_SEARCH = {
      best_practice: {
        column: "LOWER(#{BestPractice.quoted_table_name}.#{BestPractice.qcn 'name'})"
      },
      name: {
        column: "LOWER(#{quoted_table_name}.#{qcn 'name'})"
      }
    }.with_indifferent_access
  end
end
