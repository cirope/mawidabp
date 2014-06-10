module ResourceClassesHelper
  def resource_class_types
    ResourceClass::TYPES.map { |k, v| [t("resource_classes.types.#{k}"), v] }
  end

  def resources
    @resource_class.resources.build if @resource_class.resources.empty?

    @resource_class.resources
  end
end
