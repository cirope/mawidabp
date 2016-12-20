jQuery(function ($) {
  var makeRequest        = false
  var deferEnableRequest = function () {
    setTimeout(function () {
      makeRequest = true
    }, 10000)
  }

  deferEnableRequest()

  $(document).on('keyup click', function () {
    if (makeRequest && ! State.sessionExpire && $('#time-left').length) {
      makeRequest = false

      deferEnableRequest()
      $.post('/touch', State.resetTimers)
    }
  })
})
