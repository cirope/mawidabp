module RiskAssessments::Search
  extend ActiveSupport::Concern
  include Searchable

  included do
    COLUMNS_FOR_SEARCH = {
      period:      { column: "LOWER(#{Period.quoted_table_name}.#{Period.qcn 'name'})"},
      name:        { column: "LOWER(#{quoted_table_name}.#{qcn 'name'})"},
      description: { column: "LOWER(#{quoted_table_name}.#{qcn 'description'})"}
    }.with_indifferent_access
  end
end
