module FindingUserAssignments::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :process_owner, :boolean
    attribute :responsible_auditor, :boolean
    attribute :responsible_audited, :boolean
  end
end
