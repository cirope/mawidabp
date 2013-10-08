module ParametersHelper
  include Parameters::Relevance

  def relevance_field(form, *options)
    form.select :relevance,
      RELEVANCE_TYPES.map { |k,v| [t("relevance_types.#{k}"), v] }, *options
  end
end
