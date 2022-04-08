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
    var readOnly = element.data('readonly')

    if(!readOnly){
      var $checkBox = $(element.data('targetCheckbox'))
    
      if (element.find(':selected').val() == element.data('targetValueEnableCheckbox')) {
        $checkBox.removeAttr('disabled')
      } else {
        $checkBox.attr('disabled', true)
        $checkBox.prop('checked', false)
      }
    }
  }
})
