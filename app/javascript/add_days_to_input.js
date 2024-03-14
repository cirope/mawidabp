jQuery(function () {
  $(document).on('change', '[data-date-input-target]', function () {
    if ($(this).is(':checked')) {
      var newDate = $($(this).data('fromDate')).datepicker().datepicker('getDate')

      newDate.setDate(newDate.getDate() + $(this).data('addDays'))
      $($(this).data('dateInputTarget')).datepicker().datepicker('setDate', newDate)
    }
  })
})
