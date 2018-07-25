module Tasks::Validations
  extend ActiveSupport::Concern

  included do
    validates :code,
      length:      { maximum: 255 },
      uniqueness:  { scope: :finding_id },
      allow_blank: true
    validates :code, :due_on, :description, :status, presence: true
    validates :description, pdf_encoding: true
    validates :due_on, timeliness: { type: :date }, allow_blank: true
  end
end
