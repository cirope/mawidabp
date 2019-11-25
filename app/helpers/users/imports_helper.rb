module Users::ImportsHelper
  def users_import_state_badge_class(state)
    badge = {
      created:   'badge-success',
      deleted:   'badge-warning',
      error:     'badge-danger',
      unchanged: 'badge-secondary',
      updated:   'badge-info'
    }[state]

    content_tag(:span, t(".#{state}"), class: "badge #{badge}")
  end
end
