jQuery(function ($) {
  $(document).on('shown.bs.collapse', '[data-enable-disable-card-fieldset]', function (event) {
    if ($(this).data('enableDisableCardFieldset')) {
      $(this).find('fieldset').prop('disabled', false)
      $(this).find('fieldset :input:first').focus()
    }
  })

  $(document).on('hidden.bs.collapse', '[data-enable-disable-card-fieldset]', function (event) {
    if ($(this).data('enableDisableCardFieldset')) {
      $(this).find('fieldset').prop('disabled', true)
    }
  })
})
