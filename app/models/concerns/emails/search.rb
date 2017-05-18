module Emails::Search
  extend ActiveSupport::Concern

  included do
    COLUMNS_FOR_SEARCH = ActiveSupport::HashWithIndifferentAccess.new(
      to: {
        column: "LOWER(#{EMail.quoted_table_name}.#{EMail.qcn('to')})", operator: 'LIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      },
      subject: {
        column: "LOWER(#{EMail.quoted_table_name}.#{EMail.qcn('subject')})", operator: 'LIKE',
        mask: "%%%s%%", conversion_method: :to_s, regexp: /.*/
      }
    )
  end
end
