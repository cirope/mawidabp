jQuery(function ($) {
  var selector = 'input[data-date-picker]:not(.hasDatepicker, [readonly], [disabled])'

  $(document).on('focus keydown click', selector, function (event) {
    $(this).datepicker()
  })
})
