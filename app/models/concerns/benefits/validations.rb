module Benefits::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :kind, presence: true
    validates :kind, inclusion: {
      in: %w{benefit_tangible benefit_intangible damage_tangible damage_intangible}
    }
  end
end
