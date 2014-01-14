jQuery ($) ->
  $(document).on 'focus keydown click', 'input[data-date-picker]', ->
    $(this).datepicker()
