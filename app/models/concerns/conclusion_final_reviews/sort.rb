module ConclusionFinalReviews::Sort
  extend ActiveSupport::Concern

  module ClassMethods
    def columns_for_sort
      ConclusionReview.columns_for_sort.dup.merge(
        close_date: close_date_sort_options
      )
    end

    private

      def close_date_sort_options
        {
          name:  ConclusionReview.human_attribute_name('close_date'),
          field: Arel.sql("#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn 'close_date'} ASC")
        }
      end
  end
end
