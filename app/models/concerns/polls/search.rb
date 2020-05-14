module Polls::Search
  extend ActiveSupport::Concern
  include Searchable

  included do
    COLUMNS_FOR_SEARCH = {
      name: {
        column: "LOWER(#{User.quoted_table_name}.#{User.qcn 'name'})"
      },
      last_name: {
        column: "LOWER(#{User.quoted_table_name}.#{User.qcn 'last_name'})"
      },
      questionnaire_name: {
        column: "LOWER(#{Questionnaire.quoted_table_name}.#{Questionnaire.qcn 'name'})"
      },
      answered: {
        column:            "#{quoted_table_name}.#{qcn 'answered'}",
        operator:          '=',
        regexp:            /\Asi|no\z/i,
        conversion_method: ->(value) { value.downcase == 'si' }
      }
    }
  end
end
