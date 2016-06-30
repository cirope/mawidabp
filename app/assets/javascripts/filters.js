$(document).on('change', '[data-date-operator]', function (event) {
  var operator = $(this).val()
  var $until   = $(this).closest('.filter').find('[data-date-until]')

  if (operator === 'between')
    $until.removeClass('hidden')
  else
    $until.addClass('hidden')
})
