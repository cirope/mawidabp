module Organizations::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :corporate, :boolean
    attribute :finding_state_change_notification, :boolean
  end
end
