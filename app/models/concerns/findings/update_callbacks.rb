module Findings::UpdateCallbacks
  extend ActiveSupport::Concern

  included do
    before_save :can_be_modified?, :users_notification, :check_for_reiteration
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
          Notifier.notify_new_finding(fua.user, self).deliver
        end
      end
    end

    def check_for_reiteration
      if reiteration?
        raise 'Not included in review' unless review_include_repeated?
        raise 'Original finding can not be changed' if repeated_of_id_was
        raise 'Original can not be repeated' if repeated_of.repeated? && !final

        self.repeated_of.state = Finding::STATUS[:repeated]
        self.origination_date  = repeated_of.origination_date
      end
    end

    def reiteration?
      !undoing_reiteration && repeated_of_id_changed? && control_objective_item.try(:review)
    end

    def review_include_repeated?
      review = control_objective_item.try(:review)

      review.finding_review_assignments.any? do |fra|
        fra.finding_id == repeated_of_id
      end
    end

    def notify_changes_to_users
      unless incomplete?
        added = finding_user_assignments.select(&:new_record?).map(&:user)
        removed = finding_user_assignments.select(&:marked_for_destruction?).map(&:user)

        notify_changes_to added, removed unless avoid_changes_notification
      end
    end

    def notify_changes_to added, removed
      if added.present? && removed.present?
        Notifier.reassigned_findings_notification(added, removed, self, false).deliver
      elsif added.blank? && removed.present?
        Notifier.changes_notification(
          removed,
          title: responsibility_removed_title,
          organizations: [organization]
        ).deliver
      end
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
