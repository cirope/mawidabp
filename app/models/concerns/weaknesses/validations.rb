module Weaknesses::Validations
  extend ActiveSupport::Concern

  included do
    validates :risk, :priority, presence: true
    validates :audit_recommendations, presence: true, if: :notify?
    validates_each :review_code do |record, attr, value|
      regex = /\A#{record.prefix}\d+\Z/

      record.errors.add attr, :invalid unless value =~ regex
    end
  end
end
