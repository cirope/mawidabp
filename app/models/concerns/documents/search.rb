module Documents::Search
  extend ActiveSupport::Concern

  included do
    COLUMNS_FOR_SEARCH = HashWithIndifferentAccess.new(
      name: {
        column: "LOWER(#{quoted_table_name}.#{qcn('name')})", operator: 'LIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      },
      description: {
        column: "LOWER(#{quoted_table_name}.#{qcn('description')})", operator: 'LIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      },
      tags: {
        column: "LOWER(#{Tag.quoted_table_name}.#{Tag.qcn('name')})", operator: 'LIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      }
    )
  end
end
