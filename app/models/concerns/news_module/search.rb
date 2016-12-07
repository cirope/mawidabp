module NewsModule::Search
  extend ActiveSupport::Concern

  included do
    COLUMNS_FOR_SEARCH = HashWithIndifferentAccess.new(
      title: {
        column: "LOWER(#{quoted_table_name}.#{qcn('title')})", operator: 'LIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      },
      tags: {
        column: "LOWER(#{Tag.quoted_table_name}.#{Tag.qcn('name')})", operator: 'LIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      }
    )
  end
end
