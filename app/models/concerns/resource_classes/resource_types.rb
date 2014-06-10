module ResourceClasses::ResourceTypes
  TYPES = { human: 0, material: 1 }

  TYPES.each do |type, value|
    define_method(:"#{type}?") { resource_class_type == value }
  end
end
