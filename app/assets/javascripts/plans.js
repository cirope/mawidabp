jQuery(function () {
  if ($('[data-controller="plans"]').length && $('#plan_items').length) {
    FormUtil.completeSortNumbers()
    Helper.makeSortable('#plan_items', 'fieldset.plan_item', 'a.move')

    $(document).on('dynamic-item.added dynamic-item.removed', function () {
      setTimeout(FormUtil.completeSortNumbers, 300)
    })
  }
})
