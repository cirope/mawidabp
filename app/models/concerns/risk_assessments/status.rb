module RiskAssessments::Status
  extend ActiveSupport::Concern

  included do
    enum status: [:draft, :final, :merged]
  end
end
