jQuery(function () {
  $(document).on('change', '[data-date-input-target]', function () {
    if ($(this).is(":checked")) {
      var idFromDate = $(this).data('formClass').toLowerCase().concat('_', $(this).data('fromDate'))
      var dateFromParts = $('#' + idFromDate).val().split("/");
      var dateFrom = new Date(+dateFromParts[2], dateFromParts[1] - 1, +dateFromParts[0]);

      dateFrom.setDate(dateFrom.getDate() + $(this).data('addDays'))
      var dd = String(dateFrom.getDate()).padStart(2, '0');
      var mm = String(dateFrom.getMonth() + 1).padStart(2, '0');
      var yyyy = dateFrom.getFullYear();

      var idInputToAddDays = $(this).data('formClass').toLowerCase().concat('_', $(this).data('dateInputTarget'))
      $('#' + idInputToAddDays).val(dd + '/' + mm + '/' + yyyy)
    }
  })
})


