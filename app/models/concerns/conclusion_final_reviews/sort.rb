module ConclusionFinalReviews::Sort
  extend ActiveSupport::Concern

  module ClassMethods
    def columns_for_sort
      @_columns_for_sort ||= super.dup.merge(
        close_date: {
          name:  ConclusionReview.human_attribute_name('close_date'),
          field: Arel.sql("#{quoted_table_name}.#{qcn 'close_date'} ASC")
        }
      ).with_indifferent_access
    end
  end
end
