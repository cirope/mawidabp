module ConclusionReviews::SortColumns
  extend ActiveSupport::Concern

  module ClassMethods
    def order_by column = nil
      order_by = []

      order_by << if column.present?
                    columns_for_sort[column][:field]
                  else
                    Arel.sql "#{quoted_table_name}.#{qcn 'issue_date'} DESC"
                  end

      order_by << Arel.sql("#{quoted_table_name}.#{qcn 'created_at'} DESC")

      order(order_by)
    end

    def order_by_column_name column
      columns_for_sort[column]&.fetch :name, nil
    end

    private
      def columns_for_sort
        @_columns_for_sort ||= {
          issue_date:     issue_date_sort_options,
          period:         period_sort_options,
          identification: identification_sort_options
        }.with_indifferent_access
      end

      def issue_date_sort_options
        field = Arel.sql "#{quoted_table_name}.#{qcn 'issue_date'} ASC"

        {
          name:  ConclusionReview.human_attribute_name(:issue_date),
          field: field
        }
      end

      def period_sort_options
        {
          name:  Period.model_name.human,
          field: Arel.sql("#{Period.quoted_table_name}.#{Period.qcn 'name'} ASC")
        }
      end

      def identification_sort_options
        {
          name:  ::Review.human_attribute_name(:identification),
          field: Arel.sql("#{::Review.quoted_table_name}.#{::Review.qcn 'identification'} ASC")
        }
      end
  end
end
