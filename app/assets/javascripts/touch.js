/* global State */

jQuery(function ($) {
  var makeRequest        = false
  var deferEnableRequest = function () {
    setTimeout(function () {
      makeRequest = true
    }, 10000)
  }

  deferEnableRequest()

  $(document).on('keyup mouseup', function () {
    if (makeRequest && ! State.sessionExpire && $('[data-time-left]').length) {
      makeRequest = false

      deferEnableRequest()
      $.post('/touch')
    }
  })
})
