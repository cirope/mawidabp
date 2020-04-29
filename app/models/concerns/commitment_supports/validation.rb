module CommitmentSupports::Validation
  extend ActiveSupport::Concern

  included do
    validates :reason, :plan, :controls, presence: true
  end
end
