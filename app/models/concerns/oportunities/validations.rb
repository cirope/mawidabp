module Oportunities::Validations
  extend ActiveSupport::Concern

  included do
    validates_each :review_code do |record, attr, value|
      regex = /\A#{record.prefix}\d+\Z/

      record.errors.add attr, :invalid unless value =~ regex
    end
  end
end
