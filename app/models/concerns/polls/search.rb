module Polls::Search
  extend ActiveSupport::Concern

  included do
    COLUMNS_FOR_SEARCH = HashWithIndifferentAccess.new(
      name: {
        column: "LOWER(#{User.quoted_table_name}.#{User.qcn('name')})", operator: 'LIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      },
      last_name: {
        column: "LOWER(#{User.quoted_table_name}.#{User.qcn('last_name')})", operator: 'LIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      },
      questionnaire_name: {
        column: "LOWER(#{Questionnaire.quoted_table_name}.#{Questionnaire.qcn('name')})", operator: 'LIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      },
      answered: {
        column: "#{Poll.quoted_table_name}.#{Poll.qcn('answered')}", operator: '=',
        mask: '%s', regexp: /\Asi|no\z/i,
        conversion_method: ->(value) { value.downcase == 'si' }
      }
    )
  end
end
