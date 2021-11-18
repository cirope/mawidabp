module PlanItems::Scope
  extend ActiveSupport::Concern

  def cycle?
    REVIEW_SCOPES[self.scope]&.fetch(:type, nil) == :cycle
  end

  def sustantive?
    REVIEW_SCOPES[self.scope]&.fetch(:type, nil) == :sustantive
  end
end
