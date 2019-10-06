module NotificationsHelper
  def link_to_confirm notification
    unless notification.notified?
      link_to confirm_notification_path(notification), title: t('notification.confirm') do
        icon 'fas', 'check-circle'
      end
    end
  end
end
