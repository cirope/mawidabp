module Benefits::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :kind, presence: true
    validates :kind, inclusion: { in: %w{tangible intangible} }
  end
end
