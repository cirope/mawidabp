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
      removeClass('hidden').
      find('[data-toggle="popover"]').
      attr('data-content', message)
  }

  var setTimer = function (message, time) {
    message.timerId = setTimeout(function () {
      setMessage(message.message)
      setExpiration(message.expired)

      $('.navbar.navbar-default').toggleClass('navbar-default navbar-inverse')
    }, time * 1000)
  }

  var resetTimer = function (message) {
    clearTimeout(message.timerId)

    $('.navbar.navbar-inverse').toggleClass('navbar-default navbar-inverse')
    $('[data-time-left]').addClass('hidden')
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
