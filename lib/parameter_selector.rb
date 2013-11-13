# Funciones para seleccionar la correcta versión de parámetros que debe
# utilizarse
module ParameterSelector
  def parameter_in(organization_id, param_name, param_date = nil, show_value = false)
    raise 'No organization selected' unless organization_id

    Setting.find_by(name: param_name, organization_id: organization_id).try(:value)
  end

  def get_parameter(param_name, show_value = false, organization_id = nil)
    if self.respond_to?(:created_at)
      self.parameter_in(organization_id || Organization.current_id, param_name)
    end
  end

  def get_parameter_for_now(param_name, show_value = false, organization_id = nil)
    self.parameter_in(organization_id || Organization.current_id, param_name)
  end
end
