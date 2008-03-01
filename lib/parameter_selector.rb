# Funciones para seleccionar la correcta versión de parámetros que debe
# utilizarse
module ParameterSelector
  def parameter_in(organization_id, param_name, param_date = nil,
      show_value = false)
    raise 'No organization selected' unless organization_id

    parameter = Parameter.find_parameter organization_id, param_name, param_date

    if parameter.kind_of?(Array)
      parameter.map do |p|
        [
          show_value ? "#{p[0]} (#{p[1]})" : p[0],
          p[1].respond_to?(:to_i) ? p[1].to_i : p[1]
        ]
      end
    else
      parameter
    end
  end

  def get_parameter(param_name, show_value = false, organization_id = nil)
    if self.respond_to?(:created_at)
      self.parameter_in(
        organization_id || GlobalModelConfig.current_organization_id,
        param_name, self.created_at, show_value)
    end
  end

  def get_parameter_for_now(param_name, show_value = false, organization_id = nil)
    if self.respond_to?(:created_at)
      self.parameter_in(
        organization_id || GlobalModelConfig.current_organization_id,
        param_name, Time.now, show_value)
    end
  end
end