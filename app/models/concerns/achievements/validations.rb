module Achievements::Validations
  extend ActiveSupport::Concern

  included do
    validates :benefit, presence: true
    validates :comment, pdf_encoding: true
    validates :amount, numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 9_999_999_999_999.99
    }, allow_nil: true, allow_blank: true
    validate :value_attribute_present?
  end

  private

    def value_attribute_present?
      if benefit.try(:kind).to_s.match /_tangible/
        errors.add :amount, :blank if amount.blank?
      elsif benefit.try(:kind).to_s.match /_intangible/
        errors.add :comment, :blank if comment.blank?
      end
    end
end
