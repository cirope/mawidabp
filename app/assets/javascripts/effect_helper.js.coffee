window.EffectHelper =
  hide: (element, callback) -> $(element).stop().fadeOut(200, callback)

  remove: (element, callback) ->
    $(element).stop().fadeOut 200, ->
      setTimeout (-> $(element).remove()), 200
      callback() if jQuery.isFunction(callback)

  show: (e, callback) -> $(e).stop().fadeIn(1000, callback)
