# Funciones para seleccionar la correcta versión de parámetros que debe
# utilizarse
module ParameterSelector
  def parameter_in(organization_id, param_name, param_date = nil, show_value = false)
    organization_id = Organization.current_id unless organization_id

    setting = Setting.find_by(
      name: param_name, organization_id: organization_id
    ).try(:value)

    setting || DEFAULT_SETTINGS[param_name].fetch('value')
  end

  def get_parameter(param_name, show_value = false, organization_id = nil)
    self.parameter_in(organization_id, param_name)
  end

  def get_parameter_for_now(param_name, show_value = false, organization_id = nil)
    self.parameter_in(organization_id, param_name)
  end
end
