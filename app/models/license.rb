class License < ApplicationRecord
  include Auditable
  include Licenses::Constants
  include Licenses::Gateway
  include Licenses::Validations

  belongs_to :group

  enum status: {
    trial:     'trial',
    active:    'active',
    unpaid:    'unpaid',
    cancelled: 'cancelled'
  }
end
