module BusinessUnitKindsHelper
  def show_business_unit_kind?
    !HIDE_CONTROL_OBJECTIVE_ITEM_EFFECTIVENESS &&
      HIDE_FINDING_CRITERIA_MISMATCH
  end
end
