module Users::Search
  extend ActiveSupport::Concern

  included do
    COLUMNS_FOR_SEARCH = HashWithIndifferentAccess.new(
      user: {
        column: "LOWER(#{quoted_table_name}.#{qcn('user')})", operator: 'LIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      },
      name: {
        column: "LOWER(#{quoted_table_name}.#{qcn('name')})", operator: 'LIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      },
      last_name: {
        column: "LOWER(#{quoted_table_name}.#{qcn('last_name')})", operator: 'LIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      },
      function: {
        column: "LOWER(#{quoted_table_name}.#{qcn('function')})", operator: 'LIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      }
    )
  end
end
