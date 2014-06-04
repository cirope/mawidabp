module Users::Search
  extend ActiveSupport::Concern

  included do
    COLUMNS_FOR_SEARCH = HashWithIndifferentAccess.new(
      user: {
        column: "LOWER(#{table_name}.user)", operator: 'LIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      },
      name: {
        column: "LOWER(#{table_name}.name)", operator: 'LIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      },
      last_name: {
        column: "LOWER(#{table_name}.last_name)", operator: 'LIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      },
      function: {
        column: "LOWER(#{table_name}.function)", operator: 'LIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      }
    )
  end
end
