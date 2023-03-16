jQuery(function () {
  $(document).ready(function () {
    $('[data-checkbox-enable-disable-inputs]').each(function () {
      enableDisableInputs($(this))
    })
  })

  $(document).on('change', '[data-checkbox-enable-disable-inputs]', function () {
    enableDisableInputs($(this))
  })

  function enableDisableInputs(element) {
    if (element.data('checkboxEnableDisableInputs') == true) {
      $('[data-input-to-enable]').attr('disabled', !element.is(':checked'))
      $('[data-input-to-disable]').attr('disabled', element.is(':checked'))
    }
  }
})
