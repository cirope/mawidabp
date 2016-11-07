module Documents::Scopes
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order :name }
  end

  module ClassMethods
    def search query: nil
      result = ordered

      if query.present?
        result = result.where "LOWER(#{table_name}.name) LIKE ?", "%#{query.strip}%".downcase
      end

      result
    end
  end
end
