# frozen_string_literal: true

class License < ApplicationRecord
  include Auditable
  include Licenses::Constants
  include Licenses::Gateway
  include Licenses::Validations
  include Licenses::Scopes

  belongs_to :group

  enum status: {
    trial:     'trial',
    active:    'active',
    unpaid:    'unpaid',
    cancelled: 'cancelled'
  }
end
