module FindingUserAssignments::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :process_owner, :boolean
    attribute :responsible_auditor, :boolean
  end
end
