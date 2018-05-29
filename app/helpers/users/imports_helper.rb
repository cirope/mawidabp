module Users::ImportsHelper
  def users_import_state_label_class(state)
    case state
      when :created   then 'label-success'
      when :updated   then 'label-info'
      when :deleted   then 'label-warning'
      when :unchanged then 'label-default'
    end
  end
end
