module BusinessUnitTypesHelper
  def business_unit_taggings bu
    bu.taggings.build if bu.taggings.empty?

    bu.taggings
  end
end
