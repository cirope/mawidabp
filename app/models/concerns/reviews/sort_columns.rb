module Reviews::SortColumns
  extend ActiveSupport::Concern

  module ClassMethods

    def columns_for_sort
      ActiveSupport::HashWithIndifferentAccess.new(
        period_asc:          period_asc_sort_options,
        period_desc:         period_desc_sort_options,
        identification_asc:  identification_asc_sort_options,
        identification_desc: identification_desc_sort_options
      )
    end

    private

      def period_asc_sort_options
        period_sort_options
      end

      def period_desc_sort_options
        period_sort_options order: 'DESC'
      end

      def identification_asc_sort_options
        identification_sort_options
      end

      def identification_desc_sort_options
        identification_sort_options order: 'DESC'
      end

      def period_sort_options order: 'ASC'
        {
          name:  "#{Period.model_name.human}#{order_label order}",
          field: "#{Period.quoted_table_name}.#{Period.qcn 'name'} #{order}"
        }
      end

      def identification_sort_options order: 'ASC'
        {
          name:  "#{human_attribute_name 'identification'}#{order_label order}",
          field: "#{quoted_table_name}.#{qcn 'identification'} #{order}"
        }
      end

      def order_label order
        order_label = { 'ASC' => 'ascendant', 'DESC' => 'descendant' }[order]

        " (#{I18n.t "label.#{order_label}"})" if order
      end
  end
end
