jQuery(function () {
  $(document).ready(function () {
    $('[data-condition-to-receive-confirm]').submit(function(event) {
      var conditionToReceiveConfirm = $(this).data('conditionToReceiveConfirm')
      var selectedState             = $($(this).data('inputWithState')).find(':selected').val()
      var checkboxTargetchecked     = $($(this).data('checkboxTarget')).prop('checked')

      if ((conditionToReceiveConfirm == true) &&
        ($(this).data('statesTarget').includes(parseInt(selectedState))) &&
        (checkboxTargetchecked == $(this).data('targetValueCheckbox'))) {

          var message = confirm($(this).data('confirmMessage'))

            if (!message) {
              event.stopPropagation()
              event.preventDefault()
            }
        }
    })
  })
})
