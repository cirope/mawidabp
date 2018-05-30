module Users::ImportsHelper
  def users_import_state_label_class(state)
    second_label = {
      created:   'label-success',
      deleted:   'label-warning',
      error:     'label-danger',
      unchanged: 'label-default',
      updated:   'label-info'
    }[state]

    content_tag(:span, t(".#{state}"), class: "label #{second_label}")
  end
end
