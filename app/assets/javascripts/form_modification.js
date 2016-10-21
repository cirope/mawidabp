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

  $('form:not([data-no-observe-changes])').change(function () {
    State.unsavedData = true
  })

  if (window.addEventListener)
    window.addEventListener('beforeunload', _onBeforeUnload)
  else
    window.onbeforeunload = _onBeforeUnload
})
