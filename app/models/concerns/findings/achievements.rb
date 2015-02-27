module Findings::Achievements
  extend ActiveSupport::Concern

  included do
    has_many :achievements, dependent: :destroy
    accepts_nested_attributes_for :achievements, allow_destroy: true, reject_if: :value_attribute_blank
  end

  private

    def value_attribute_blank attributes
      attributes['comment'].blank? && attributes['amount'].blank?
    end
end
