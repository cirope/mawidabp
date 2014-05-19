jQuery ($) ->
  selector = 'input[data-date-picker]:not(.hasDatepicker, [readonly], [disabled])'

  $(document).on 'focus keydown click', selector, -> $(this).datepicker()
