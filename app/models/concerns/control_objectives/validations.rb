module ControlObjectives::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, pdf_encoding: true, presence: true
    validates :relevance, :risk, numericality: { only_integer: true },
      allow_nil: true, allow_blank: true
    validate :has_control
  end

  private

    def has_control
      has_active_control = control && !control.marked_for_destruction?

      errors.add :control, :blank unless has_active_control
    end
end
