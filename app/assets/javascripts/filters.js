$(document).on('change', '[data-date-operator]', function (event) {
  var operator = $(this).val()
  var $until   = $(this).closest('[data-filter]').find('[data-date-until]')

  if (operator === 'between')
    $until.removeAttr('hidden')
  else
    $until.attr('hidden', true)
})
