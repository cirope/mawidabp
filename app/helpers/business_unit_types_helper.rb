module BusinessUnitTypesHelper
  def tagging bu
    bu.taggings.build if bu.taggings.empty?
  end
end
