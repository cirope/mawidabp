module Findings::BusinessUnits
  extend ActiveSupport::Concern

  included do
    has_many :business_unit_findings, dependent: :destroy
    has_many :business_units, through: :business_unit_findings
  end
end
