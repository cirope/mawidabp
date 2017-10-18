module ConclusionReviews::SortColumns
  extend ActiveSupport::Concern

  module ClassMethods

    def columns_for_sort
      ActiveSupport::HashWithIndifferentAccess.new(
        issue_date:     issue_date_sort_options,
        period:         period_sort_options,
        identification: identification_sort_options
      )
    end

    private

      def issue_date_sort_options
        field = "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn 'issue_date'} ASC"

        {
          name:  ConclusionReview.human_attribute_name(:issue_date),
          field: field
        }
      end

      def period_sort_options
        {
          name:  Period.model_name.human,
          field: "#{Period.quoted_table_name}.#{Period.qcn 'name'} ASC"
        }
      end

      def identification_sort_options
        {
          name:  Review.human_attribute_name(:identification),
          field: "#{Review.quoted_table_name}.#{Review.qcn 'identification'} ASC"
        }
      end
  end
end
