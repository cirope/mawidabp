module RiskAssessmentTemplates::Search
  extend ActiveSupport::Concern
  include Searchable

  included do
    COLUMNS_FOR_SEARCH = {
      name:        { column: "LOWER(#{quoted_table_name}.#{qcn 'name'})" },
      description: { column: "LOWER(#{quoted_table_name}.#{qcn 'description'})" }
    }.with_indifferent_access
  end
end
