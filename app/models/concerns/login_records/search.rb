module LoginRecords::Search
  extend ActiveSupport::Concern

  included do
    COLUMNS_FOR_SEARCH = HashWithIndifferentAccess.new({
      user: {
        column: "LOWER(#{User.quoted_table_name}.#{User.qcn('user')})", operator: 'LIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      },
      data: {
        column: "LOWER(#{quoted_table_name}.#{qcn('data')})", operator: 'LIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      }
    })
  end
end
