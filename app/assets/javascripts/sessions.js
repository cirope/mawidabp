/* global State */

jQuery(function ($) {
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
      find('[data-toggle="popover"]').
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

  $(document).bind({
    ajaxSuccess: resetTimers
  })

  $('[data-toggle="popover"]').popover()
})
