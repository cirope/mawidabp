jQuery ($) ->
  selector = 'input[data-date-picker]:not(.hasDatepicker)'

  $(document).on 'focus keydown click', selector, -> $(this).datepicker()
