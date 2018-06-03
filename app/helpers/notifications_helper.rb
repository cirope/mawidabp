module NotificationsHelper
  # Devuelve el HTML de un vínculo para confirmar una notificación
  #
  # * <em>notification</em>:: La notificación para la que se quiere generar el
  #                           link
  def link_to_confirm(notification, reject = false)
    unless notification.notified?
      if reject
        link_to(t('notification.reject'),
          confirm_notification_path(notification, reject: 1))
      else
        link_to(t('notification.confirm'),
          confirm_notification_path(notification))
      end
    end
  end
end