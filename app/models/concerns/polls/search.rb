module Polls::Search
  extend ActiveSupport::Concern

  included do
    COLUMNS_FOR_SEARCH = HashWithIndifferentAccess.new(
      name: {
        column: "#{User.table_name}.name", operator: 'ILIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      },
      last_name: {
        column: "#{User.table_name}.last_name", operator: 'ILIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      },
      questionnaire_name: {
        column: "#{Questionnaire.table_name}.name", operator: 'ILIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      },
      answered: {
        column: "#{Poll.table_name}.answered", operator: '=',
        mask: '%s', regexp: /\Asi|no\z/i,
        conversion_method: ->(value) { value.downcase == 'si' }
      }
    )
  end
end
