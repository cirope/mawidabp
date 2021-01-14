module BusinessUnitTypesHelper
  def business_unit_tagging bu
    bu.taggings.build if bu.taggings.empty?
  end
end
