jQuery(function () {
  $(document).ready(function () {
    $('[data-target-values-enable-checkbox]').each(function () {
      modifyCheckbox($(this))
    })
  })

  $(document).on('change', '[data-target-values-enable-checkbox]', function () {
    modifyCheckbox($(this))
  })

  function modifyCheckbox(element) {
    var $checkBox = $(element.data('targetCheckbox'))

    if (element.data('targetValuesEnableCheckbox').includes(parseInt(element.find(':selected').val()))) {
      $checkBox.removeAttr('disabled')
    } else {
      $checkBox.attr('disabled', true)
      $checkBox.prop('checked', false)
    }
  }
})
