module Polls::Search
  extend ActiveSupport::Concern

  included do
    COLUMNS_FOR_SEARCH = HashWithIndifferentAccess.new(
      name: {
        column: "LOWER(#{User.table_name}.name)", operator: 'ILIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      },
      last_name: {
        column: "LOWER(#{User.table_name}.last_name)", operator: 'ILIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      },
      questionnaire_name: {
        column: "LOWER(#{Questionnaire.table_name}.name)", operator: 'ILIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      },
      answered: {
        column: "#{Poll.table_name}.answered", operator: '=',
        conversion_method: lambda { |value|
          if value.downcase == 'si'
            true
          elsif value.downcase == 'no'
            false
          else
            nil
          end
        }
      }
    )
  end
end
