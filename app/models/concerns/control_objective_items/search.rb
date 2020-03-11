module ControlObjectiveItems::Search
  extend ActiveSupport::Concern
  include Searchable

  included do
    COLUMNS_FOR_SEARCH = {
      review:  {
        column: "LOWER(#{Review.quoted_table_name}.#{Review.qcn 'identification'})"
      },
      process_control: {
        column: "LOWER(#{ProcessControl.quoted_table_name}.#{ProcessControl.qcn 'name'})"
      },
      control_objective_text: {
        column: "LOWER(#{quoted_table_name}.#{qcn 'control_objective_text'})"
      }
    }.with_indifferent_access
  end
end
