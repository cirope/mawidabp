module Tags::Scopes
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order name: :asc }
  end

  module ClassMethods
    def search query: nil
      result = ordered

      if query.present?
        result = result.where "LOWER(#{table_name}.name) LIKE ?", "%#{query.strip}%".downcase
      end

      result
    end

    Tag::KINDS.each do |kind|
      define_method("for_#{kind.pluralize}") { where kind: kind }
    end
  end
end
