module Oportunities::SortColumns
  extend ActiveSupport::Concern

  module ClassMethods
    def columns_for_sort
      Finding.columns_for_sort.except(
        :risk_asc, :risk_desc, :follow_up_date_asc, :follow_up_date_desc,
        :priority_asc, :priority_desc, :readings_desc
      )
    end
  end
end
