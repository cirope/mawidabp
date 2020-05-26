module Endorsements::Notifications
  extend ActiveSupport::Concern

  included do
    after_commit :notify_creation, on: :create
    after_commit :notify_change, on: :update
  end

  private

    def notify_creation
      NotifierMailer.new_endorsement(organization.id, id).deliver_later
    end

    def notify_change
      if status_previously_changed? && !pending?
        NotifierMailer.endorsement_update(organization.id, id).deliver_later
      end
    end
end
