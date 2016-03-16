module Questions::Validations
  extend ActiveSupport::Concern
  include Questions::Constants

  included do
    validates :sort_order, :question, :answer_type, presence: true
    validates :sort_order, numericality: { only_integer: true },
      allow_nil: true, allow_blank: true
    validates :question, length: { maximum: 255 }, allow_nil: true,
      allow_blank: true
    validates :answer_type, inclusion: { in: ANSWER_TYPES.values }, allow_nil: true,
      allow_blank: true
  end
end
