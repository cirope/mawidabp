module Users::ImportsHelper
  def users_import_state_badge_class(state)
    badge = {
      created:   'bg-success',
      deleted:   'bg-warning',
      errored:   'bg-danger',
      unchanged: 'bg-secondary',
      updated:   'bg-info'
    }[state]

    content_tag(:span, t(".#{state}"), class: "badge #{badge}")
  end
end
