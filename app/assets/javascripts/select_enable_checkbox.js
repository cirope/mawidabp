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
    var idCheckBox = element.data('formClass').toLowerCase().concat('_', element.data('targetCheckbox'))
    var $checkBox = $('#' + idCheckBox)

    if (element.find(':selected').val() == element.data('targetValueEnableCheckbox')) {  
      $checkBox.removeAttr("disabled");
    } else {
      $checkBox.attr("disabled", true);
      if (element.data('disabledAndDeny')) {
        $checkBox.prop('checked', false);
      }
    }
  }
})


