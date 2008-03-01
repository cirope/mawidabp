module ParametersHelper
  def add_parameter_value_link(name)
    link_to_function name do |page|
      page.insert_html :bottom, :parameter_value,
        :partial => 'parameter_value',
        :locals => {:number => rand(), :item => ['', '']}
    end
  end
end