module Plans::Validations
  extend ActiveSupport::Concern


  included do
    validates :period_id, :organization, presence: true
    validates :period_id, uniqueness: true, allow_nil: true, allow_blank: true
    validates_each :plan_items do |record, attr, value|
      if value.any? { |pi| pi.marked_for_destruction? && !pi.can_be_destroyed? }
        record.errors.add attr, :locked
      end
    end
  end
end
