jQuery(function () {
  var _resetForms = function () {
    $('form').each(function (i, form) {
      $(form).find(':input, :checkbox').each(function (i, e) {
        var $e         = $(e)
        var resetValue = $e.data('resetValue')

        if (resetValue) $e.val(resetValue)
      })
    })
  }

  var _onBeforeUnload = function (event) {
    if (State.unsavedData) {
      _resetForms()

      if (event) event.returnValue = State.unsavedDataWarning

      return State.unsavedDataWarning
    }
  }

  if (window.addEventListener)
    window.addEventListener('beforeunload', _onBeforeUnload)
  else
    window.onbeforeunload = _onBeforeUnload

  $(document).on('change', 'form:not([data-no-observe-changes])', function () {
    State.unsavedData = true
  })

  $(document).on('click', '[data-ignore-unsaved-data]', function () {
    var unsavedData   = State.unsavedData

    State.unsavedData = false

    setTimeout(function () {
      State.unsavedData = unsavedData
    }, 100)
  })
})
