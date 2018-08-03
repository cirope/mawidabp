jQuery(function ($) {
  var rejectRegex = /\.\.\//

  $(document).on('submit', 'form', function (event) {
    var $form = $(this)

    $form.data('rejected', false)

    $.each($form.serializeArray(), function (i, element) {
      if (element.value && element.value.match(rejectRegex)) {
        $('[name="' + element.name + '"]').
          closest('.form-group').
          addClass('has-error')

        $form.data('rejected', true)
      }
    })

    if ($form.data('rejected') && State.rejectedDataFormat) {
      event.preventDefault()
      event.stopPropagation()

      alert(State.rejectedDataFormat)

      setTimeout(function () {
        $form.find('input[type="submit"][disabled]').removeProp('disabled')
      }, 150)
    }
  })

  $(document).on('submit', 'form', function (event) {
    var $form     = $(this)
    var hasErrors = false

    $form.find('[data-required=true]').each(function (i, element) {
      $field = $(element)

      if ($field.val().match(/^\s*$/)) {
        hasErrors = true

        $field.closest('.form-group').addClass('has-error')
      } else {
        $field.closest('form-group').removeClass('has-error')
      }
    })

    if (hasErrors && State.validationFailedMessage) {
      event.stopPropagation()
      event.preventDefault()

      alert(State.validationFailedMessage)

      setTimeout(function () {
        $form.find('input[type="submit"]').removeProp('disabled')
      }, 300)
    } else if (! $form.data('rejected')) {
      State.unsavedData = false

      // Remove submit button and "snowman"
      $form.
        find('input[type="submit"], input[name="utf8"]').
        prop('disabled', true)
    }
  })
})
