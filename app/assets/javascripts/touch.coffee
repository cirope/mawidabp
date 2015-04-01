jQuery ($) ->
  makeRequest        = false
  deferEnableRequest = -> setTimeout((-> makeRequest = true), 10000)

  deferEnableRequest()

  $(document).on 'keyup click', ->
    if makeRequest && !State.sessionExpire && $('#time-left').length
      makeRequest = false

      deferEnableRequest()
      $.get '/touch', State.resetTimers
