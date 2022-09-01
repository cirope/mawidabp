module ParameterSelector
  def parameter_in(organization_id, param_name, param_date = nil, show_value = false)
    organization_id = Current.organization&.id unless organization_id

    Current.settings                  ||= {}
    Current.settings[organization_id] ||= Hash[
      Setting.where(organization_id: organization_id).pluck(:name, :value)
    ].with_indifferent_access

    setting = Current.settings[organization_id][param_name]

    setting || DEFAULT_SETTINGS[param_name].fetch('value')
  end

  def get_parameter(param_name, show_value = false, organization_id = nil)
    self.parameter_in(organization_id, param_name)
  end
end
