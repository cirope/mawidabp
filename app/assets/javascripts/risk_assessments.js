jQuery(function ($) {
  $(document).on('autocomplete:update', '[data-complete-business-unit-type]', function () {
    var $input = $(this)
    var target = $input.data('completeBusinessUnitType')
    var data   = $input.data('item')

    $(target).val(data.informal)
  })
})
