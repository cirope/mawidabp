/* global State */

jQuery(function ($) {
  var timeLeft                  = $('[data-time-left]').attr('data-time-left')
  var sessionExpiresMessage     = $('[data-time-left]').attr('data-session-expires-message')
  var sessionTimeMessage        = $('[data-time-left]').attr('data-session-time-message')
  var rejectedDataFormatMessage = $('[data-time-left]').attr('data-rejected-data-format-message')
  var unsavedDataWarningMessage = $('[data-time-left]').attr('data-unsaved-data-warning-message')
  var validationFailedMessage   = $('[data-time-left]').attr('data-validation-failed-message')

  var setExpiration = function (expired) {
    State.sessionExpire = State.sessionExpire || expired

    if (State.sessionExpire)
      $('[data-time-left]').
        find('.text-warning').
        toggleClass('text-warning text-danger')
  }

  var setMessage = function (message) {
    $('[data-time-left]').
      removeAttr('hidden').
      find('[data-bs-toggle="popover"]').
      attr('data-content', message)
  }

  var setTimer = function (message, time) {
    message.timerId = setTimeout(function () {
      setMessage(message.message)
      setExpiration(message.expired)

      $('.navbar.bg-light').toggleClass('bg-light bg-dark')
      $('.navbar.navbar-light').toggleClass('navbar-light navbar-dark')
    }, time * 1000)
  }

  var resetTimer = function (message) {
    clearTimeout(message.timerId)

    $('.navbar.bg-dark').toggleClass('bg-light bg-dark')
    $('.navbar.navbar-dark').toggleClass('navbar-light navbar-dark')
    $('[data-time-left]').attr('hidden', true)
  }

  var resetTimers = function () {
    $.each(State.showMessages, function () {
      if (! State.sessionExpire) {
        resetTimer(this)
        setTimer(this, this.time)
      }
    })
  }

  setTimeout(function () {
    if (Array.isArray(State.showMessages)) {
      $.each(State.showMessages, function () {
        if (! this.timerId) setTimer(this, this.time - 15)
      })
    }
  }, 15000)

  setTimeout(function () {
    State.showMessages = [{
      time: (timeLeft - 2) * 60 - 10,
      message: sessionExpiresMessage,
      expired: false
    }, {
      time: timeLeft * 60 - 10,
      message: sessionTimeMessage,
      expired: true
    }]
  }, 10000)

  setTimeout(function () {
    State.rejectedDataFormat      = rejectedDataFormatMessage
    State.unsavedDataWarning      = unsavedDataWarningMessage
    State.validationFailedMessage = validationFailedMessage
  })

  $(document).bind({
    ajaxSuccess: resetTimers
  })

  $('[data-bs-toggle="popover"]').popover()
})
