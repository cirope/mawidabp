module Users::ImportsHelper
  def users_import_state_label_class(state)
    {
      created:   'label-success',
      updated:   'label-info',
      deleted:   'label-warning',
      unchanged: 'label-default'
    }[state]
  end
end
