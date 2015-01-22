module Findings::UpdateCallbacks
  extend ActiveSupport::Concern

  included do
    before_save :can_be_modified?, :users_notification
    after_update :notify_changes_to_users
  end

  def can_be_modified?
    unless allow_modification?
      msg = I18n.t('finding.readonly')

      errors.add :base, msg unless errors.full_messages.include? msg

      false
    end
  end

  private

    def allow_modification?
      force_modification || final == false || final_changed? ||
        (repeated? && state_changed?) ||
        (!changed? && !control_objective_item.review.is_frozen?)
    end

    def users_notification
      send_users_notifications unless incomplete?
    end

    def send_users_notifications
      finding_user_assignments.each do |fua|
        if users_for_notification.to_a.map(&:to_i).include? fua.user_id
          NotifierMailer.notify_new_finding(fua.user, self).deliver_later
        end
      end
    end

    def notify_changes_to_users
      unless incomplete?
        notify_changes unless avoid_changes_notification
      end
    end

    def notify_changes
      if users_added.present? && users_removed.present?
        NotifierMailer.reassigned_findings_notification(
          users_added, users_removed, self, false
        ).deliver_later
      elsif users_added.blank? && users_removed.present?
        NotifierMailer.changes_notification(
          users_removed,
          title: responsibility_removed_title,
          organizations: [organization]
        ).deliver_later
      end
    end

    def users_added
      finding_user_assignments.select(&:new_record?).map &:user
    end

    def users_removed
      finding_user_assignments.select(&:marked_for_destruction?).map &:user
    end

    def responsibility_removed_title
      I18n.t(
        'finding.responsibility_removed',
        class_name: self.class.model_name.human.downcase,
        review_code: review_code,
        review: review.try(:identification)
      )
    end
end
