module ConclusionReviews::Search
  extend ActiveSupport::Concern
  include Searchable

  included do
    GENERIC_COLUMNS_FOR_SEARCH = {
      issue_date: {
        column:            "#{quoted_table_name}.#{qcn 'issue_date'}",
        conversion_method: -> (value) { Timeliness.parse(value, :date).to_fs :db },
        mask:              '%s',
        operator:          SEARCH_ALLOWED_OPERATORS.values,
        regexp:            SEARCH_DATE_REGEXP
      },
      period: {
        column: "LOWER(#{Period.quoted_table_name}.#{Period.qcn 'name'})"
      },
      identification: {
        column: "LOWER(#{::Review.quoted_table_name}.#{::Review.qcn 'identification'})"
      },
      summary: {
        column: "LOWER(#{quoted_table_name}.#{qcn 'summary'})"
      },
      business_unit: {
        column: "LOWER(#{BusinessUnit.quoted_table_name}.#{BusinessUnit.qcn 'name'})"
      },
      project: {
        column: "LOWER(#{PlanItem.quoted_table_name}.#{PlanItem.qcn 'project'})"
      }
    }.with_indifferent_access
  end
end
