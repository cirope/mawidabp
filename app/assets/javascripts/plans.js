jQuery(function () {
  if ($('#plan_items').length)
    Helper.makeSortable('#plan_items', 'fieldset.plan_item', 'a.move')
})
