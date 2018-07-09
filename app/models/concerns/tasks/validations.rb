module Tasks::Validations
  extend ActiveSupport::Concern

  included do
    validates :due_on, :description, :status, presence: true
    validates :description, pdf_encoding: true
    validates :due_on, timeliness: { type: :date }, allow_blank: true
  end
end
