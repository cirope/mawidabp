jQuery(function () {
  $(document).ready(function () {
    $('[data-condition-to-receive-confirm]').submit(function() {
      debugger;
      if (($(this).data('conditionToReceiveConfirm') == true) && 
            ($($(this).data('inputWithState')).find(':selected').val() == $(this).data('stateTarget')) && 
            ($($(this).data('checkboxTarget')).prop('checked') == $(this).data('targetValueCheckbox'))) {
        
              message = confirm($(this).data('confirmMessage'));

              if(message) {
                return true
              } else {
               return false
              }

      } else {
        return true
      }
    })
  })
})


