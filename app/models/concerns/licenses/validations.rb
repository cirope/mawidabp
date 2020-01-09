module Licenses::Validations
  extend ActiveSupport::Concern

  included do
    validates :auditors_limit, inclusion: { in: LICENSE_PLANS.keys }
    validates :subscription_id, uniqueness: true,
      if: :will_save_change_to_subscription_id?
  end
end
