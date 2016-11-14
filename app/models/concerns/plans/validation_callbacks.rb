module Plans::ValidationCallbacks
  extend ActiveSupport::Concern

  included do
    before_validation :set_proper_parent
  end

  private

    def set_proper_parent
      plan_items.each { |pi| pi.plan = self }
    end
end
