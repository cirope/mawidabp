module BestPractices::Search
  extend ActiveSupport::Concern

  included do
    COLUMNS_FOR_SEARCH = {
      name: "#{quoted_table_name}.#{qcn 'name'}".freeze
    }.with_indifferent_access
  end

  module ClassMethods
    def search query: nil, columns: []
      result = ordered

      if query.present?
        columns.each do |column|
          if (quoted_column = COLUMNS_FOR_SEARCH[column])
            result = result.where "LOWER(#{quoted_column}) LIKE ?", "%#{query.strip.downcase}%"
          end
        end
      end

      result
    end
  end
end
