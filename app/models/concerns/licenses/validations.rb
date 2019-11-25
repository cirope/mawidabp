module Licenses::Validations
  extend ActiveSupport::Concern

  included do
    validates :auditors_limit, inclusion: { in: LICENSE_PLANS.keys }
  end
end
