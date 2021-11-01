jQuery(function () {
  $(document).ready(function () {
    $('[data-target-value-enable-checkbox]').each(function () {
      modifyCheckbox($(this))
    })
  })

  $(document).on('change', '[data-target-value-enable-checkbox]', function () {
    modifyCheckbox($(this))
  })

  function modifyCheckbox(element) {
    var $checkBox = $(element.data('targetCheckbox'))

    if (element.find(':selected').val() == element.data('targetValueEnableCheckbox')) {
      $checkBox.removeAttr('disabled')
    } else {
      $checkBox.attr('disabled', true)

      if (element.data('disabledAndDeny')) {
        $checkBox.prop('checked', false)
      }
    }
  }
})
