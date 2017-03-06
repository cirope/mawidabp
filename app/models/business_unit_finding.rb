class BusinessUnitFinding < ApplicationRecord
  include Auditable

  validates :business_unit_id, presence: true

  belongs_to :business_unit
  belongs_to :finding
end
